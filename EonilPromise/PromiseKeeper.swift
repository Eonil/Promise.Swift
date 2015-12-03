//
//  PromiseKeeper.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/03.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

/// A utilty to provide simpler promise management.
public final class PromiseKeeper<T> {
	public init(cancel: ()->()) {
		self.cancel = cancel
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
				cancel!()
			default:
				break
			}
			cancel = nil
			promise.result = result
		}
	}
	private var cancel: (()->())?
//	func ready(value: T){
//		promise.result
//	}
//	func error(error: ErrorType) {
//
//	}
//	func cancel() {
//
//	}
}