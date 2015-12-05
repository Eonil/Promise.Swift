//
//  PromiseUtility.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public struct PromiseUtility {
	public static func chainSourceCancellationToDestinationIfItIsNotYetConcluded<T,U>(source: Promise<T>, destination: Promise<U>) {
		source.then { [weak destination] (result: PromiseResult<T>) -> Promise<()> in
			switch result {
			case .Cancel:
				guard let destination = destination else { break }
				guard destination.result == nil else { break }
				destination.cancel()
			default:
				break
			}
			return Promise(value: ())
		}
	}
}