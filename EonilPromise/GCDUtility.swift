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
	static func dispatchInMainThreadAynchronously(code: ()->()) {
		dispatch_async(dispatch_get_main_queue()) {
			code()
		}
	}
	static func dispatchInNonMainThreadAsynchronously(code: ()->()) {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
			if NSThread.isMainThread() {
				dispatchInNonMainThreadAsynchronously(code)
			}
			else {
				code()
			}
		}
	}
}