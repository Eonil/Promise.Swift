//
//  Cancellable.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/03.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public protocol Cancellable: class {
	func cancel()
}
