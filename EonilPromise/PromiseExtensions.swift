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
	/// Terminates promise chain.
	public func then(continuation: T -> ()) {
		_ = then({ (value: T) -> Promise<()> in
			continuation(value)
			return Promise<()>(value: ())
		})
	}
	public func then<U>(continuation: T -> Promise<U>) -> Promise<U> {
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
	public func thenExecuteUnstoppableOperationInNonMainThread<U>(unstoppableNonMainThreadOperation: T->PromiseResult<U>) -> Promise<U> {
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
}

public enum PromiseNSURLRequestError: ErrorType {
	case CompleteWithNoErrorAndNoData(request: NSURLRequest, response: NSURLResponse?)
}
public extension Promise where T: NSURLRequest {
	public func thenExecuteNSURLSessionDataTask() -> Promise<NSData> {
		return then { (value: T) -> Promise<NSData> in
			let subpromise = Promise<NSData>()
			let request = value
			let onComplete = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
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
			let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: onComplete)
			subpromise.onCancel = { [task] in
				task.cancel()
			}
			task.resume()
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
















