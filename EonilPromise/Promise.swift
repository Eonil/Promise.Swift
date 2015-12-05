//
//  Promise.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/01.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public protocol CancellablePromiseType: class {
	func cancel()
	weak var superpromise: CancellablePromiseType? { get }
}

private let QUEUE_IDENTIFIER_KEY = {
	struct Local {
		static let marker = NSObject()
	}
	return unsafeAddressOf(Local.marker)
}() as UnsafePointer<Void>

/// A promise of eventual value.
///
/// Cancelling a promise will cause immediate resolution of all
/// subpromises.
///
/// Promise needs an explicit owner.
/// You're responsible to keep this object alive until 
/// result to be resolved. Promise `cancel`s when it dies.
/// Promise owns and keeps alive all spawned subpromises.
/// So you don't need to keep them yourself. Anyway, you
/// still can `cancel` those subromises. Cancelling subpromise
/// won't affect any other promises.
///
/// Lifecycle Management
/// --------------------
/// By default, a promise needs an owner to alive. If promise
/// dies before result, that is guaranteed to crash because we
/// cannot proper behavior on that situation. You're responsible
/// to keep alive a promise.
/// For your convenience, there's some utilities to make this
/// easier. `PromiseUtility.keep` function provides an implicit
/// owner for a promise, and releases the promise at its conclusion.
/// This is enough for most cases.
///
/// Subpromises
/// -----------
/// A promise can spawn multiple subpromises.
///
/// Cancellation Considerations
/// ---------------------------
/// Cancellation of a promise will be applied only to the promise.
/// If the promise has been derived from another promise, the source
/// promise will continue. If you want to cancel source promise, then
/// you need to cancel that source promise directly.
///
/// Thread Consideration
/// --------------------
/// Currently, you can use promise only in main thread. If you want 
/// to execute some code in background, you must a promise which does 
/// that.
public class Promise<T>: CancellablePromiseType {

	public init(notify: (PromiseResult<T>->())->(), cancel: ()->()) {
		assertMainThread()
		_onCancel = cancel
		notify { [weak self] in
			self?.result = $0
		}
	}
	internal init(cancel: ()->()) {
		assertMainThread()
		_onCancel = cancel
	}
	deinit {
		assertMainThread()
		if result == nil {
			cancel()
		}
	}

	/// Superpromise can die before subpromise dies.
	public private(set) weak var superpromise: CancellablePromiseType? {
		willSet {
			assertMainThread()
		}
	}

	// MARK: -

	/// `nil` until promise operation finishes.
	public internal(set) var result: PromiseResult<T>? {
		willSet {
			assertMainThread()
			precondition(result == nil, "This promise `\(self)` already been finished with result `\(result)`.")
			precondition(newValue != nil, "You cannot set `nil` as `result` of a promise because `nil` means result undecided.")
		}
		didSet {
			_propagateResultToSubpromisesIfAvailable()
		}
	}

	/// Cancells promise.
	/// All promise observers will receive `.Cancel` result immediately.
	/// All subpromises derived from this promise will also be cancelled
	/// immediately.
	public func cancel() {
		assertMainThread()
		guard result == nil else {
			fatalError("You can call `cancel` only once on a promise.")
		}
		_onCancel()
		result = PromiseResult.Cancel
	}
//	/// Blocks caller thread until future comes up.
//	public func wait() {
//	}

	/// Chains synchronous result handler.
	public func resultInMainThread(onResult: PromiseResult<T>->()) -> Promise<()> {
		assertMainThread()
		let sink = { (superResult: PromiseResult<T>) -> PromiseResult<()> in
			onResult(superResult)
			return superResult.map({ T->() in () })
		}
		return _map(sink, inQueue: GCDUtility.mainThreadQueue())
	}
	/// Chains synchronous mapping.
	/// Mapping operation cannot be cancelled if once it's been started.
	/// - Parameter map:	Maps a ready value `T` into `U` in main thread.
	///			`Result.Error` will be passed on any error.
	public func mapInMainThread<U>(map: T throws ->U) -> Promise<U> {
		assertMainThread()
		return	_map({ $0.map(map) }, inQueue: GCDUtility.mainThreadQueue())
	}
	/// Chains synchronous mapping.
	/// Mapping operation cannot be cancelled if once it's been started.
	/// - Parameter map:	Maps a ready value `T` into `U` in non-main thread.
	///			`Result.Error` will be passed on any error.
	public func mapInNonMainThread<U>(map: T throws ->U) -> Promise<U> {
		assertMainThread()
		return	_map({ $0.map(map) }, inQueue: GCDUtility.nonMainThreadQueue())
	}
	/// Chains asynchronous operation.
	/// This method returns a promise that;
	/// 1. waits for current promise until it to produce result,
	/// 2. calls `continuation` to get another promise to wait,
	/// 3. and also waits for the returned promise.
	///
	/// This method returns a promise that will provide result that
	/// returned from the promise that returned from the continuation.
	///
	/// - Parameter continuation:	
	///	Will be called from the thread that sets `result` of this
	///	promise.
	///	This promise will "borrow" the returned promise. Which means
	///	weak referencing, `continuation` function is responsible to 
	/// 	keep the returning promise to be alive it completes.
	///
	public func then<U>(continuation: T throws -> Promise<U>) -> Promise<U> {
		assertMainThread()
		let subpromise = Promise<U>()
		subpromise.superpromise = self
		_subpromiseCallbacks.append { [subpromise, continuation] superpromise in
			guard let superResult = superpromise.result else {
				fatalError("Expects super-promise to be concluded at this point.")
			}
			switch superResult {
			case .Ready(let value):
				do {
					weak var intermediatePromise = try continuation(value)
					precondition(intermediatePromise != nil, "The promise already been dead.")
					if let intermediatePromise = intermediatePromise {
						subpromise.superpromise = intermediatePromise
						intermediatePromise.resultInMainThread({ (intermediateResult: PromiseResult<U>) -> () in
							subpromise.result = intermediateResult
						})
					}
				}
				catch let error {
					subpromise.result = .Error(error)
				}
			case .Error(let error):
				subpromise.result = .Error(error)
			case .Cancel:
				subpromise.result = .Cancel
			}
		}
		_subpromiseIdentifiers.append(ObjectIdentifier(subpromise))
		_propagateResultToSubpromisesIfAvailable()
		return subpromise
	}
	/// Executes `continuation` when finished.
	public func then(continuation: T->()) {

	}

	// MARK: -
	private let _onCancel: ()->()
	private var _subpromiseCallbacks: [Promise<T>->()] = []
	private var _subpromiseIdentifiers: [ObjectIdentifier] = []
	private func processCancellationOfSubpromise(subpromiseIdentifier: ObjectIdentifier) {
		assertMainThread()
		guard let index = _subpromiseIdentifiers.indexOf(subpromiseIdentifier) else {
			fatalError("Cannot find subpromiseIdentifier `\(subpromiseIdentifier)` from subpromise identifier list.")
		}
		_ = _subpromiseCallbacks.removeAtIndex(index)
		_ = _subpromiseIdentifiers.removeAtIndex(index)
	}
	private func _map<U>(map: PromiseResult<T>->PromiseResult<U>, inQueue queue: dispatch_queue_t, asynchronously: Bool = true) -> Promise<U> {
		assertMainThread()
		let subpromise = Promise<U>()
		subpromise.superpromise = self
		_subpromiseCallbacks.append { [subpromise] superpromise in
			precondition(subpromise.result == nil, "The subpromise `\(subpromise)` shouldn't be resolved yet at this point.")
			guard let superResult = superpromise.result else {
				fatalError("Expects super-promise to be concluded at this point.")
			}
			let conclude = { [subpromise] in
				// Subpromise can be cancelled.
				if let subresult = subpromise.result {
					precondition(subresult.isCancel, "If subpromise has been resolved, it must be `.Cancel`.")
					return
				}
				subpromise.result = map(superResult)
			}
			dispatch_async(queue, conclude)
		}
		_subpromiseIdentifiers.append(ObjectIdentifier(subpromise))
		_propagateResultToSubpromisesIfAvailable()
		return subpromise
	}
	private func _propagateResultToSubpromisesIfAvailable() {
		assertMainThread()
		guard let _ = result else {
			return
		}
		// `sp` keeps a strong reference to the subpromise.
		// This makes subpromise alive until notification finishes.
		for sp in _subpromiseCallbacks {
			sp(self)
		}
		_subpromiseCallbacks = []
		_subpromiseIdentifiers = []
	}
}

///// A derived promise from another promise.
/////
///// You can track up to upper promise tree nodes to cancel them.
/////
//internal class Subpromise<T>: Promise<T> {
//	override weak var superpromise: Cancellable? {
//		get {
//			return _superpromise
//		}
//	}
//
//	override func cancel() {
//		super.cancel()
//		superpromise!.processCancellationOfSubpromise(ObjectIdentifier(self))
//	}
//
//	private weak var _superpromise: protocol<Cancellable, SuperpromiseType>?
//}
//
//
//
//
//
//private protocol SuperpromiseType: class {
//	func processCancellationOfSubpromise(subpromiseIdentifier: ObjectIdentifier)
//}



