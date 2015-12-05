//
//  PromiseUtility.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public struct PromiseUtility {
	/// Instantiates a promise that executes unstoppable operation in non-main thread.
	/// "Unstoppable" means the operation will NOT actually be stopped on cancellation,
	/// will continue to execute until finishes. And result will just be ignored.
	public static func promiseUnstoppableNonMainThreadExecution<T>(unstoppableNonMainThreadExecution: ()->PromiseResult<T>) -> Promise<T> {
		assertMainThread()
		let isCancelled = CancellationToken()
		let notify = { (onResult: PromiseResult<T> -> ()) -> () in
			GCDUtility.continueInNonMainThreadAsynchronously {
				let result = unstoppableNonMainThreadExecution()
				GCDUtility.continueInMainThreadAynchronously {
					assertMainThread()
					guard isCancelled.state == false else { return }
					onResult(result)
				}
			}

		}
		let cancel = { () -> () in
			assertMainThread()
			isCancelled.state = true
		}
		return Promise(notify: notify, cancel: cancel)
	}
	/// Instantiates a promise that already been concluded to be ready with a value.
	public static func promiseOfValue<T>(value: T) -> Promise<T> {
		return promiseOfResult(PromiseResult<T>.Ready(value))
	}
	/// Instantiates a promise that already been concluded to a result.
	public static func promiseOfResult<T>(result: PromiseResult<T>) -> Promise<T> {
		return Promise(notify: { $0(result) }, cancel: {})
	}
}

private class CancellationToken { var state = false }