//
//  PromiseKeeper.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/03.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

/// A utilty to provide simpler promise management.
///
/// A promise requires owner to alive, and this works as the owner.
/// Killing this object will trigger cancellation of the owned promise.
/// 
public final class PromiseKeeper<T> {
	public init(cancel: ()->()) {
		onCancel = cancel
	}
	deinit {
		if promise.result == nil {
			promise.result = PromiseResult<T>.Cancel
		}
	}

	public let promise = Promise<T>()
	public var result: PromiseResult<T>? {
		willSet {
			precondition(result == nil, "You cannot set result if a result already been bound.")
			precondition(newValue != nil, "You cannot set result to `nil`.")
		}
		didSet {
			switch result! {
			case .Cancel:
				onCancel!() // This can be called only once.
			default:
				break
			}
			onCancel = nil
			promise.result = result
		}
	}
	private var onCancel: (()->())?
}
extension PromiseKeeper {
	func ready(value: T){
		promise.result = .Ready(value)
	}
	func error(error: ErrorType) {
		promise.result = .Error(error)
	}
	func cancel() {
		promise.result = .Cancel
	}
}
extension PromiseKeeper {
	/// Keeps specified promise in default keeper in main thread.
	/// This provides an implicit owner for a promise that holds 
	/// a strong reference to the promise until the promise 
	/// concludes.
	static func keepInMainThread(promise: Promise<T>) {
		_defaultMainThreadHolder.holdUntilConcludeResult(promise)
	}
}
private var _defaultMainThreadHolder = PromiseHolder()


















