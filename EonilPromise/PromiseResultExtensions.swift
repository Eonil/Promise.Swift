//
//  PromiseResultExtensions.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public extension PromiseResult {
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

extension PromiseResult {
	var isCancel: Bool {
		get {
			switch self {
			case .Cancel:	return true
			default:	return false
			}
		}
	}
}