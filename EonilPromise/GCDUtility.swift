//
//  GCDUtility.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/11/30.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

struct GCDUtility {
	static func mainThreadQueue() -> dispatch_queue_t {
		return	dispatch_get_main_queue()
	}
	static func nonMainThreadQueue() -> dispatch_queue_t {
		struct Local {
			static var dummy: UInt8 = 0
			static var isMarked: Bool = false
		}
		if Local.isMarked == false {
			dispatch_queue_set_specific(dispatch_get_main_queue(), &Local.dummy, &Local.dummy, nil)
			Local.isMarked = true
		}
		let	q	=	dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
		if dispatch_queue_get_specific(q, &Local.dummy) == &Local.dummy {
			return	nonMainThreadQueue()
		}
		return	q
	}
	static func continueInMainThreadAynchronously(continuation: ()->()) {
		dispatch_async(dispatch_get_main_queue()) {
			continuation()
		}
	}
	static func continueInNonMainThreadAsynchronously(continuation: ()->()) {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
			if NSThread.isMainThread() {
				continueInNonMainThreadAsynchronously(continuation)
			}
			else {
				continuation()
			}
		}
	}
	static func delayAndContinueInMainThreadAsynchronously(duration: NSTimeInterval, continuation: ()->()) {
		let time = dispatch_time(DISPATCH_TIME_NOW, Int64(duration * NSTimeInterval(NSEC_PER_SEC)))
		dispatch_after(time, mainThreadQueue(), continuation)
	}
	static func delayAndContinueInNonMainThreadAsynchronously(duration: NSTimeInterval, continuation: ()->()) {
		let time = dispatch_time(DISPATCH_TIME_NOW, Int64(duration * NSTimeInterval(NSEC_PER_SEC)))
		dispatch_after(time, nonMainThreadQueue(), continuation)
	}
}

//private func _markQueue(queue: dispatch_queue_t) {
//	dispatch_queue_set_specific(queue, unsafeAddressOf(self), unsafeBitCast(unsafeAddressOf(self), UnsafeMutablePointer<Void>.self), nil)
//}
//private func _unmarkQueue(queue: dispatch_queue_t) {
//	dispatch_queue_set_specific(queue, unsafeAddressOf(self), unsafeBitCast(unsafeAddressOf(self), UnsafeMutablePointer<Void>.self), nil)
//}
//private func _checkQueue(queue: dispatch_queue_t) {
//	guard dispatch_queue_get_specific(queue, unsafeAddressOf(self)) == unsafeAddressOf(self) else {
//		fatalError()
//	}
//}