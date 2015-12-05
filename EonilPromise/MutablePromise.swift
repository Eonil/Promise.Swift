//
//  MutablePromise.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

/// You can make your own custom promise using this class.
public final class MutablePromise<T>: Promise<T> {
	public override init() {
		super.init()
	}
	public public(set) override var result: PromiseResult<T>? {
		didSet {
		}
	}
	public override var onCancel: (()->())? {
		didSet {
		}
	}
}