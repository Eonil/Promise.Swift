//
//  PromiseResult.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

public enum PromiseResult<T> {
	case Cancel
	case Error(ErrorType)
	case Ready(T)
}
