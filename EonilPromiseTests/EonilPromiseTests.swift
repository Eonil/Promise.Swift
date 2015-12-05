//
//  EonilPromiseTests.swift
//  EonilPromiseTests
//
//  Created by Hoon H. on 2015/12/02.
//  Copyright © 2015 Eonil. All rights reserved.
//

import XCTest
@testable import EonilPromise

class EonilPromiseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}

extension EonilPromiseTests {
	func test1() {
		let expect = expectationWithDescription("")
//		func produceStringFromInt(v: Int) -> Promise<String> {
//			return PromiseUtility.promiseUnstoppableNonMainThreadExecution({ () -> PromiseResult<String> in
//				assert(NSThread.isMainThread() == false)
//				sleep(1)
//				return .Ready("\(v)ABC")
//			}).keep()
//		}
//		let promise1 = PromiseUtility.promiseUnstoppableNonMainThreadExecution { () -> PromiseResult<Int> in
//			assert(NSThread.isMainThread() == false)
//			sleep(1)
//			return .Ready(111)
//		}.keep()
//
//		promise1.then(produceStringFromInt).then { (result: String) -> Promise<()> in
//			assert(NSThread.isMainThread() == true)
//			if result == "111ABC" {
//				expect.fulfill()
//			}
//			return PromiseUtility.promiseOfValue(()).keep()
//		}

		Promise.ofValue(111).then { (a: Int) -> Promise<String> in
			let b = "\(a)ABC"
			return Promise<String>.ofValue(b).keep()
		}.keep().then { (b: String) -> Promise<()> in
			print(b)
			if b == "111ABC" {
				expect.fulfill()
			}
			return Promise<()>.ofValue(()).keep()
		}.keep()

		waitForExpectationsWithTimeout(10, handler: nil)
	}
}

















