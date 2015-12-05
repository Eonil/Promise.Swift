//
//  Weak.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public struct Weak<T: AnyObject> {
	public internal(set) weak var object: T?
}