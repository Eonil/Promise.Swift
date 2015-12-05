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
		let exp = expectationWithDescription("")
		Promise(value: ()).thenExecuteUnstoppableOperationInNonMainThread { () -> PromiseResult<Int> in
			sleep(1)
			return .Ready(111)
			} .then { (value: Int) -> Promise<()> in
				sleep(1)
				if value == 111 {
					exp.fulfill()
				}
				return Promise(value: ())
		}


		waitForExpectationsWithTimeout(10, handler: { error in
			XCTAssert(error == nil)
			XCTAssert(promiseInstanceCount == 0)
		})
	}
	func test2() {
		let exp = expectationWithDescription("A")
		Promise(value: ()).thenWaitAlways(2).then {
			exp.fulfill()
		}
		waitForExpectationsWithTimeout(10) { error in
			XCTAssert(error == nil)
			XCTAssert(promiseInstanceCount == 0)
		}
	}
	func test3() {
		let exp = expectationWithDescription("A")
		Promise(value: ()).thenWaitAlways(1).thenWaitAlways(1).then {
			exp.fulfill()
		}
		waitForExpectationsWithTimeout(10) { error in
			XCTAssert(error == nil)
			XCTAssert(promiseInstanceCount == 0)
		}
	}
}

















