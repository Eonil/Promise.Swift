//
//  Promise.swift
//  Promise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

internal var promiseInstanceCount = 0

/// Lifecycling
/// -----------
/// A promise with no owner will die immediately. You're responsible to
/// keep a promise alive until it to be concluded to a result.
/// If a promise dies with no result, it will crash the app.
/// If you derive subpromises, super-promise will keep astrong references
/// to them. So they will alive while superpromise alive. But you're still
/// responsible to life of subpromises after superpromise dead.
///
/// Cancellation
/// ------------
/// Promise does not provide cascade cancellation. Cancelling a promise
/// cancels only the promise, and any superpromise won't be cancelled.
/// Anyway, you can find superpromises from `superpromise` property, and 
/// cancel them yourself.
/// Promises always propagate cancellation to all subpromises, and how to
/// process the cancellation is fully up to subpromises. If you really want,
/// you can build a subpromise that treats cancellation as a kind of success.
///
/// Promise vs Task
/// ---------------
/// They're almost equal, but different because task describes the operation
/// itself, so implies its result won't be kept. Promise implies a resulting
/// value, so you can treat this as a fuzzy state.
///
//public class Promise<T>: CancellablePromiseType {
public class Promise<T> {


	/// Instantiates an unconcluded promise.
	/// You're responsible to keep this promise alive until it to be 
	/// concluded.
	internal init() {
		assertMainThread()
		promiseInstanceCount += 1
	}
	deinit {
		assertMainThread()
		promiseInstanceCount -= 1
		print("instanceCount: \(promiseInstanceCount)")
		precondition(result != nil, "A promise dead before it to be concluded to a result. You SHOULD NOT do this. Always manage promises to conclude to a result.")
	}

//	/// A reference to super-promise.
//	/// The only thing you can do on super-promise is cancellation.
//	public private(set) weak var superpromise: CancellablePromiseType?

	/// Cancels this promise.
	/// Take care that super-promises won't be cancelled by this call.
	/// If you want to cancel a super-promise, you should find and cancel
	/// it explicitly from `superpromise` chain.
	public final func cancel() {
		assertMainThread()
		result = .Cancel
	}

 	/// State of this promise.
	/// `nil` if this promise has not been concluded.
	/// Non-`nil` value if this promise has neem concluded.
	public internal(set) var result: PromiseResult<T>? {
		willSet {
			assertMainThread()
			precondition(result == nil, "You can set `result` only once.")
		}
		didSet {
			if result!.isCancel {
				onCancel?()
				onCancel = nil
			}
			for continuation in continuationQueue {
				continuation()
			}
			continuationQueue = []
		}
	}

	/// A closure to be called on cancellation.
	internal var onCancel: (()->())? {
		willSet {
			precondition(onCancel == nil)
		}
	}

	/// Chains a continuation promise.
	/// - Parameter coninuation:
	///	Takes result of current promise and produces an "intermediate promise".
	///	`continuation` is responsible to keep alive this "intermediate promise".
	///	`continuation` will always be executed regardless of cancellation state of
	///	returned subpromise.
	/// - Returns:
	///	A continuation subpromise.
	///	Returned subpromise will be concluded as soon as the "intermediate promise"
	///	concluded.
	///	Current promise will keep a strong reference to returning subpromise.
	///	When current promise concludes, it moves ownership to "intermediate promise".
	///	So subpromise will survive until "intermediate promise" concludes.
	/// - Note:
	///	All other `then~` methods will and SHOULD ultimately call this method to
	///	provide proper handling of continuation.
	public final func then<U>(continuation: PromiseResult<T> -> Promise<U>) -> Promise<U> {
		assertMainThread()
		let subpromise = Promise<U>()
//		subpromise.superpromise = self
		queueContinuation { [weak self, subpromise, continuation] in // Owns `subpromise` and `continuation`.
			assertMainThread()
			precondition(self != nil, "Continuation must be called while this promise is alive.")
			precondition(self!.result != nil, "Continuation must be called after this promise has been concluded.")
			let intermediatePromise = continuation(self!.result!)
//			subpromise.superpromise = intermediatePromise // Old superpromise has been concluded. Switch over superpromise for cascade cancellation.
			intermediatePromise.queueContinuation { [weak intermediatePromise, subpromise] in // Also switches over owner. Now intermediate promise owns the subpromise.
				assertMainThread()
				precondition(intermediatePromise != nil, "Continuation must be called while this promise is alive.")
				precondition(intermediatePromise!.result != nil, "Continuation must be called after this promise has been concluded.")
				guard subpromise.result == nil else {
					// Abandon result if cancelled.
					if let subresult = subpromise.result {
						if subresult.isCancel {
							return
						}
					}
					// Otherwise, it's a critical error.
					fatalError()
				}
				subpromise.result = intermediatePromise!.result!
			}
		}
		return subpromise
	}

	// MARK: -
	private var continuationQueue: [() -> ()] = [] {
		willSet {
			assertMainThread()
			precondition(newValue.count == 0 || result == nil, "You can append a continuation only while this promise has not been concluded.")
		}
	}
	private func queueContinuation(continuation: ()->()){
		if let _ = result {
			continuation()
		}
		else {
			continuationQueue.append(continuation)
		}
	}
}

//public protocol CancellablePromiseType: class {
//	func cancel()
//	weak var superpromise: CancellablePromiseType? { get }
//}
