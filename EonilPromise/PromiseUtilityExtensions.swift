//
//  PromiseUtilityExtensions.swift
//  EonilPromise
//
//  Created by Hoon H. on 2015/12/05.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

extension PromiseUtility {
	enum PromiseUtilityError: ErrorType {
		case NSURLSessionDataTaskCompleteWithNoErrorAndNoData
	}

	/// Instantiates a promise that executes `NSURLSessionDataTask`.
	static func promiseNSURLSessionDataTask(request: NSURLRequest) -> Promise<NSData> {
		
		let cancel = {
		}
		let promise = Promise<NSData>(cancel: cancel)
		let setResult = { [weak promise] (result: PromiseResult<NSData>) -> () in
			guard let promise = promise else {
				fatalError("Expected promise to be alive at this point.")
			}
			promise.result = result
		}
		let onComplete = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
			if let error = error {
				if error.code == NSURLErrorCancelled {
					setResult(.Cancel)
					return
				}
				else {
					setResult(.Error(error))
					return
				}
			}
			if data == nil {
				setResult(.Error(PromiseUtilityError.NSURLSessionDataTaskCompleteWithNoErrorAndNoData))
				return
			}
		}
		let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: onComplete)
		task.resume()
		return promise
	}
}