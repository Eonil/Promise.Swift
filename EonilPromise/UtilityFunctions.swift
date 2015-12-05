//
//  UtilityFunctions.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/03.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

protocol Reconfiguarable: class {
}
extension Reconfiguarable {
	func reconfigure(@noescape f: Self->()) -> Self {
		f(self)
		return self
	}
}

func assertMainThread() {
	assert(NSThread.isMainThread(), "Currently, you can promise only in main thread. Non-main thread execution may be supported later, but right now.")
}

