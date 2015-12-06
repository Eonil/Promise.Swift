//
//  PromiseExtensions.swift
//  Promise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public extension Promise {
	public convenience init(result: PromiseResult<T>) {
		self.init()
		self.result = result
	}
	public convenience init(error: ErrorType) {
		self.init()
		self.result = PromiseResult.Error(error)
	}
	public convenience init(value: T) {
		self.init()
		self.result = PromiseResult<T>.Ready(value)
	}
	public convenience init(unstoppableNonMainThreadExecution: ()->PromiseResult<T>) {
		self.init()
		GCDUtility.continueInNonMainThreadAsynchronously { [weak self] in
			let result = unstoppableNonMainThreadExecution()
			GCDUtility.continueInMainThreadAynchronously { [weak self] in
				assertMainThread()
				precondition(self != nil)
				self!.result = result
			}
		}
	}
}

//public extension Promise {
//	/// Also cancels specified promise when this promise cancels.
//	public func <U>(promise: Promise<U>) {
//		// This is an a bit optimized implementation.
//		// This also can be implemented using `then` chaining.
//		let oldOnCancel = onCancel
//		onCancel = { [weak promise] in
//			oldOnCancel?()
//			guard let promise = promise else { return }
//			guard promise.result == nil else { return }
//			promise.cancel()
//		}
//	}
//}
public extension Promise {
	public func then(continuation: ()->()) {
		then { (_: PromiseResult<T>) -> () in
			continuation()
		}
	}
	/// Terminates promise chain regardless of result state.
	public func then(continuation: PromiseResult<T> -> ()) {
		_ = then({ (result: PromiseResult<T>) -> Promise<()> in
			continuation(result)
			return Promise<()>(value: ())
		})
	}
	/// Terminates promise chain on ready state.
	public func thenOnReady(continuation: T -> ()) {
		_ = thenOnReady({ (value: T) -> Promise<()> in
			continuation(value)
			return Promise<()>(value: ())
		})
	}
	public func thenOnReady<U>(continuation: T -> Promise<U>) -> Promise<U> {
		return then({ (result: PromiseResult<T>) -> Promise<U> in
			switch result {
			case .Ready(let value):
				return continuation(value)
			case .Error(let error):
				return Promise<U>(error: error)
			case .Cancel:
				return Promise<U>(result: PromiseResult<U>.Cancel)
			}
		})
	}

//	public func then<U>(continuation: (result: PromiseResult<T>, onComplete: (result: PromiseResult<U>) -> ()) -> ()) -> Promise<U> {
//		return then({ (result: PromiseResult<T>) -> Promise<U> in
//			let subpromise = Promise<U>()
//			let onComplete = { subpromise.result = $0 }
//			continuation(result: result, onComplete: onComplete)
//			return subpromise
//		})
//	}
//	public func then<U>(continuation: (value: T, onComplete: (PromiseResult<U>) -> ()) -> ()) -> Promise<U> {
//		return then({ (value: T) -> Promise<U> in
//			let subpromise = Promise<U>()
//			let onComplete = { (result: PromiseResult<U>) -> () in
//				subpromise.result = result
//			}
//			continuation(value: value, onComplete: onComplete)
//			return subpromise
//		})
//	}
}

extension Promise {
	/// Waits unconditionally. This always wait even on error or cancel.
	func thenWaitAlways(durationInSeconds: NSTimeInterval) -> Promise<T> {
		return thenWaitConditionally(durationInSeconds, condition: { _ in
			return true
		})
	}
	/// Waits only on ready state. Doesn't wait on error or cancel.
	func thenWaitOnReady(durationInSeconds: NSTimeInterval) -> Promise<T> {
		return thenWaitConditionally(durationInSeconds, condition: { (result: PromiseResult<T>) -> Bool in
			switch result {
			case .Ready:	return true
			default:	return false
			}
		})
	}
	/// Waits only on ready state. Doesn't wait on error or cancel.
	func thenWaitOnError(durationInSeconds: NSTimeInterval) -> Promise<T> {
		return thenWaitConditionally(durationInSeconds, condition: { (result: PromiseResult<T>) -> Bool in
			switch result {
			case .Error:	return true
			default:	return false
			}
		})
	}
	/// Waits only on ready state. Doesn't wait on error or cancel.
	func thenWaitOnCancel(durationInSeconds: NSTimeInterval) -> Promise<T> {
		return thenWaitConditionally(durationInSeconds, condition: { (result: PromiseResult<T>) -> Bool in
			switch result {
			case .Cancel:	return true
			default:	return false
			}
		})
	}
	/// Waits conditionally.
	func thenWaitConditionally(durationInSeconds: NSTimeInterval, condition: PromiseResult<T> -> Bool) -> Promise<T> {
		return then({ (result: PromiseResult<T>) -> Promise<T> in
			print(result)
			guard condition(result) else {
				return Promise(result: result)
			}
			let subpromise = Promise<T>()
			let time = dispatch_time(DISPATCH_TIME_NOW, Int64(durationInSeconds * NSTimeInterval(NSEC_PER_SEC)))
			dispatch_after(time, GCDUtility.mainThreadQueue()) {
				if subpromise.result != nil && subpromise.result!.isCancel {
					return
				}
				subpromise.result = result
			}
			return subpromise
		})
	}
}
extension Promise {
	public func waitForPromise<U>(otherPromise: Promise<U>) -> Promise<T> {
		return then({ (result: PromiseResult<T>) -> Promise<T> in
			let subpromise = Promise<T>()
			otherPromise.then({ () -> () in
				subpromise.result = result
			})
			return subpromise
		})
	}
}
extension Promise {
	public func thenExecuteUnstoppableOperationInNonMainThread<U>(unstoppableNonMainThreadOperation: PromiseResult<T>->PromiseResult<U>) -> Promise<U> {
		return then { (result: PromiseResult<T>) -> Promise<U> in
			let subpromise = Promise<U>()
			GCDUtility.continueInNonMainThreadAsynchronously {
				let result = unstoppableNonMainThreadOperation(result)
				GCDUtility.continueInMainThreadAynchronously {
					assertMainThread()
					subpromise.result = result
				}
			}
			return subpromise
		}
	}
	public func thenExecuteUnstoppableOperationInNonMainThreadOnReady<U>(unstoppableNonMainThreadOperation: T->PromiseResult<U>) -> Promise<U> {
		return thenExecuteUnstoppableOperationInNonMainThread { (result: PromiseResult<T>) -> PromiseResult<U> in
			switch result {
			case .Ready(let value):
				return unstoppableNonMainThreadOperation(value)
			case .Error(let error):
				return .Error(error)
			case .Cancel:
				return .Cancel
			}
		}
	}
	public func thenExecuteUnstoppableOperationInNonMainThreadOnReady<U>(unstoppableNonMainThreadOperation: T throws -> U) -> Promise<U> {
		return thenExecuteUnstoppableOperationInNonMainThread { (result: PromiseResult<T>) -> PromiseResult<U> in
			switch result {
			case .Ready(let value):
				do {
					return .Ready(try unstoppableNonMainThreadOperation(value))
				}
				catch let error {
					return .Error(error)
				}
			case .Error(let error):
				return .Error(error)
			case .Cancel:
				return .Cancel
			}
		}
	}
}

public enum PromiseNSURLRequestError: ErrorType {
	case CompleteWithNoErrorAndNoData(request: NSURLRequest, response: NSURLResponse?)
}
public extension Promise {
	public func thenExecuteNSURLSessionDataTask(continuation: T throws -> NSURLRequest) -> Promise<NSData> {
		return thenOnReady { (value: T) -> Promise<NSData> in
			let subpromise = Promise<NSData>()
			do {
				let request = try continuation(value)
				let onComplete = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
					GCDUtility.continueInMainThreadAynchronously {
						if let error = error {
							if error.code == NSURLErrorCancelled {
								subpromise.result = .Cancel
								return
							}
							subpromise.result = .Error(error)
							return
						}
						if let data = data {
							subpromise.result = .Ready(data)
							return
						}
						let error = PromiseNSURLRequestError.CompleteWithNoErrorAndNoData(request: request, response: response)
						subpromise.result = .Error(error)
						return
					}
				}
				let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: onComplete)
				subpromise.onCancel = { [task] in
					task.cancel()
				}
				task.resume()
			}
			catch let error {
				subpromise.result = .Error(error)
			}
			return subpromise
		}
	}
}


//public protocol CancellableTaskType {
//	typealias Value
//	func run(onSuccess onSuccess: Value->(), onFailure: ErrorType->())
//	func cancel()
//}
//public extension Promise {
//	public func thenExecuteCancellableTask<U: CancellableTaskType>(task: U) -> Promise<U.Value> {
//		let subpromise = Promise<U.Value>()
//		let onSuccess = { (value: U.Value) -> () in
//			subpromise.result = .Ready(value)
//		}
//		let onFailure = { (error: ErrorType) -> () in
//			subpromise.result = .Error(error)
//		}
//		task.run(onSuccess: onSuccess, onFailure: onFailure)
//		subpromise.onCancel = { task.cancel() }
//		return subpromise
//	}
//}
















