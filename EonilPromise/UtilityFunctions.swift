//
//  UtilityFunctions.swift
//  Promise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

func assertMainThread() {
	assert(NSThread.isMainThread())
}