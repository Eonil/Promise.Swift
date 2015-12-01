//
//  Promise2Holder.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/01.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

/// Keeps strong reference to promises until it finishes.
public class Promise2Holder {
	public func holdUntilDone<T>(promise: Promise2<T>) {
		precondition(NSThread.isMainThread())
		let id = ObjectIdentifier(promise)
		_promises[id] = promise
		promise.resultInMainThread { [weak self] (result: Promise2Result<T>) -> () in
			guard self != nil else {
				return
			}
			self!._promises[id] = nil
		}
	}

	// MARK: -
	private var _promises: [ObjectIdentifier: AnyObject] = [:]
}