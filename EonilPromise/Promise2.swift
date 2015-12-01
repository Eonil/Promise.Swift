//
//  Promise2.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/01.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation


public enum Promise2Result<T> {
	case Ready(T)
	case Cancel
	case Error(ErrorType)

	public var value: T? {
		get {
			switch self {
			case .Ready(let value):	return 	value
			default:		return	nil
			}
		}
	}
	public var error: ErrorType? {
		get {
			switch self {
			case .Error(let error):	return 	error
			default:		return	nil
			}
		}
	}
	public var isReady: Bool {
		get {
			return	value != nil
		}
	}
	public var isCancel: Bool {
		get {
			switch self {
			case .Cancel:		return 	true
			default:		return	false
			}
		}
	}
	public var isError: Bool {
		get {
			return	error != nil
		}
	}
	public func map<U>(map: T throws ->U) -> Promise2Result<U> {
		switch self {
		case .Cancel:		return	.Cancel
		case .Error(let error):	return	.Error(error)
		case .Ready(let value):	do {
				let value1 = try map(value)
				return .Ready(value1)
			}
			catch let error {
				return	.Error(error)
			}
		}
	}
}

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
public class Promise2<T> {
	public init(notify: (Promise2Result<T>->())->(), cancel: ()->()) {
		notify { [weak self] in
			self?.result = $0
		}
	}
	private init() {
	}
	deinit {
		if result == nil {
			cancel()
		}
	}

	// MARK: -

	/// `nil` until promise operation finishes.
	public private(set) var result: Promise2Result<T>? {
		willSet {
			precondition(result == nil, "This promise `\(self)` already been finished with result `\(result)`.")
		}
		didSet {
			// `sp` keeps a strong reference to the subpromise.
			// This makes subpromise alive until notification finishes.
			for sp in _subpromises {
				sp(self)
			}
			_subpromises = []
		}
	}

	/// Cancells promise.
	/// All promise observers will receive `.Cancel` result immediately.
	/// All subpromises derived from this promise will also be cancelled
	/// immediately.
	public func cancel() {
		result = Promise2Result.Cancel
	}
//	public func wait() {
//	}

	public func resultInMainThread(onResult: Promise2Result<T>->()) -> Promise2<()> {
		let sink = { (superResult: Promise2Result<T>) -> Promise2Result<()> in
			print(superResult)
			onResult(superResult)
			return superResult.map({ T->() in () })
		}
		return _map(sink, inQueue: GCDUtility.mainThreadQueue())
	}
	/// - Parameter map:	Maps a ready value `T` into `U` in main thread.
	///			`Result.Error` will be passed on any error.
	public func mapInMainThread<U>(map: T throws ->U) -> Promise2<U> {
		return	_map({ $0.map(map) }, inQueue: GCDUtility.mainThreadQueue())
	}
	/// - Parameter map:	Maps a ready value `T` into `U` in non-main thread.
	///			`Result.Error` will be passed on any error.
	public func mapInNonMainThread<U>(map: T throws ->U) -> Promise2<U> {
		return	_map({ $0.map(map) }, inQueue: GCDUtility.nonMainThreadQueue())
	}

	// MARK: -
	private var _subpromises: [Promise2<T>->()] = []

	private func _map<U>(map: Promise2Result<T>->Promise2Result<U>, inQueue queue: dispatch_queue_t, asynchronously: Bool = true) -> Promise2<U> {
		precondition(asynchronously == true)
		if let result = result {
			let subpromise = Promise2<U>()
			subpromise.result = map(result)
			return subpromise
		}

		let subpromise = Promise2<U>()
		_subpromises.append { [subpromise] in
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
		return subpromise
	}
}










