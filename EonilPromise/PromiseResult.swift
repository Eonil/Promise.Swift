//
//  PromiseResult.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/03.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public enum PromiseResult<T> {
	case Ready(T)
	case Cancel
	case Error(ErrorType)

	public var value: T? {
		get {
			switch self {
			case .Ready(let value):	return 	value
			default:		return	nil
			}
		}
	}
	public var error: ErrorType? {
		get {
			switch self {
			case .Error(let error):	return 	error
			default:		return	nil
			}
		}
	}
	public var isReady: Bool {
		get {
			return	value != nil
		}
	}
	public var isCancel: Bool {
		get {
			switch self {
			case .Cancel:		return 	true
			default:		return	false
			}
		}
	}
	public var isError: Bool {
		get {
			return	error != nil
		}
	}
	public func map<U>(map: T throws ->U) -> PromiseResult<U> {
		switch self {
		case .Cancel:		return	.Cancel
		case .Error(let error):	return	.Error(error)
		case .Ready(let value):	do {
			let value1 = try map(value)
			return .Ready(value1)
		}
		catch let error {
			return	.Error(error)
			}
		}
	}
}