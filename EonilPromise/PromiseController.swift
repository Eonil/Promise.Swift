//
//  PromiseController.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/02.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

class PromiseController<T> {
	init(_ instantiate: ()->Promise2<T>) {
		_instantiate = instantiate
	}

	func run() {
		cancel()
		_promise = _instantiate()
	}
	func cancel() {
		_promise?.cancel()
		_promise = nil
	}


	// MARK: -
	private let _instantiate: ()->Promise2<T>
	private var _promise: Promise2<T>?
}