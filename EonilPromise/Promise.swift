//
//  Promise.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/01.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

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
/// Cancellation Considerations
/// ---------------------------
/// Cancellation of a promise will be applied only to the promise.
/// If the promise has been derived from another promise, the source
/// promise will continue. If you want to cancel source promise, then
/// you need to cancel that source promise directly.
///
public class Promise<T>: Cancellable {
	public init(notify: (PromiseResult<T>->())->(), cancel: ()->()) {
		notify { [weak self] in
			self?.result = $0
		}
	}
	internal init() {
	}
	deinit {
		if result == nil {
			cancel()
		}
	}

	// MARK: -

	/// `nil` until promise operation finishes.
	public internal(set) var result: PromiseResult<T>? {
		willSet {
			precondition(result == nil, "This promise `\(self)` already been finished with result `\(result)`.")
		}
		didSet {
			// `sp` keeps a strong reference to the subpromise.
			// This makes subpromise alive until notification finishes.
			for sp in _subpromiseCallbacks {
				sp(self)
			}
			_subpromiseCallbacks = []
			_subpromiseIdentifiers = []
		}
	}

	/// Cancells promise.
	/// All promise observers will receive `.Cancel` result immediately.
	/// All subpromises derived from this promise will also be cancelled
	/// immediately.
	public func cancel() {
		guard result == nil else {
			return
		}
		result = PromiseResult.Cancel
	}
//	/// Blocks caller thread until future comes up.
//	public func wait() {
//	}

	/// Chains synchronous result handler.
	public func resultInMainThread(onResult: PromiseResult<T>->()) -> Subpromise<()> {
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
	public func mapInMainThread<U>(map: T throws ->U) -> Subpromise<U> {
		return	_map({ $0.map(map) }, inQueue: GCDUtility.mainThreadQueue())
	}
	/// Chains synchronous mapping.
	/// Mapping operation cannot be cancelled if once it's been started.
	/// - Parameter map:	Maps a ready value `T` into `U` in non-main thread.
	///			`Result.Error` will be passed on any error.
	public func mapInNonMainThread<U>(map: T throws ->U) -> Subpromise<U> {
		return	_map({ $0.map(map) }, inQueue: GCDUtility.nonMainThreadQueue())
	}
//	/// Chains asynchronous operation.
//	/// A call to map returns a new promise, and this method will return a subpromise
//	/// that waits for the result of promise returned from the map function.
//	public func chain<U>(map: T throws -> Promise<U>) -> Subpromise<U> {
//
//	}

	// MARK: -
	private var _subpromiseCallbacks: [Promise<T>->()] = []
	private var _subpromiseIdentifiers: [ObjectIdentifier] = []
	private func _map<U>(map: PromiseResult<T>->PromiseResult<U>, inQueue queue: dispatch_queue_t, asynchronously: Bool = true) -> Subpromise<U> {
		precondition(asynchronously == true)
		if let result = result {
			let subpromise = Subpromise<U>()
			subpromise._superpromise = self
			subpromise.result = map(result)
			return subpromise
		}

		let subpromise = Subpromise<U>()
		subpromise._superpromise = self
		_subpromiseCallbacks.append { [subpromise] in
			precondition(subpromise.result == nil, "The subpromise `\(subpromise)` shouldn't be resolved yet at this point.")
			guard let superResult = $0.result else {
				fatalError("Expects super-promise to be realized at this point.")
			}
			dispatch_async(queue) { [subpromise] in
				// Subpromise can be cancelled.
				if let subresult = subpromise.result {
					precondition(subresult.isCancel, "If subpromise has been resolved, it must be `.Cancel`.")
					return
				}
				subpromise.result = map(superResult)
			}
		}
		_subpromiseIdentifiers.append(ObjectIdentifier(subpromise))
		return subpromise
	}
}
extension Promise: SuperpromiseType {
	private func processCancellationOfSubpromise(subpromiseIdentifier: ObjectIdentifier) {
		guard let index = _subpromiseIdentifiers.indexOf(subpromiseIdentifier) else {
			fatalError("Cannot find subpromiseIdentifier `\(subpromiseIdentifier)` from subpromise identifier list.")
		}
		_ = _subpromiseCallbacks.removeAtIndex(index)
		_ = _subpromiseIdentifiers.removeAtIndex(index)
	}
}

/// A derived promise from another promise.
///
/// You can track up to upper promise tree nodes to cancel them.
///
public class Subpromise<T>: Promise<T> {
	private override init() {
		super.init()
	}

	/// Superpromise can die before subpromise dies.
	public weak var superpromise: Cancellable? {
		get {
			return _superpromise
		}
	}

	public override func cancel() {
		super.cancel()
		_superpromise!.processCancellationOfSubpromise(ObjectIdentifier(self))
	}

	private weak var _superpromise: protocol<Cancellable, SuperpromiseType>?
}





private protocol SuperpromiseType: class {
	func processCancellationOfSubpromise(subpromiseIdentifier: ObjectIdentifier)
}




