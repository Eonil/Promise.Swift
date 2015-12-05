//
//  PromiseHolder.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/01.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

/// Keeps strong reference to promises until it finishes.
public class PromiseHolder {
	public init() {
	}
	public func holdUntilConcludeResult<T>(promise: Promise<T>) {
		precondition(NSThread.isMainThread())
		let id = ObjectIdentifier(promise)
		_promises[id] = promise
		promise.resultInMainThread { [weak self] (result: PromiseResult<T>) -> () in
			guard self != nil else {
				return
			}
			self!._promises[id] = nil
		}
	}

	// MARK: -
	private var _promises: [ObjectIdentifier: AnyObject] = [:]
}