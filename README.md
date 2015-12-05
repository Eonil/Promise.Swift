# Promise.Swift

Promise library for Swift.

- Clear owner and lifecycling.
- Simple and easy interface.
- Main, non-main thread aware dispatching.

How to Use
----------

	Promise(value: ()).thenExecuteUnstoppableOperationInNonMainThread { () -> PromiseResult<Int> in
		sleep(1)
		return .Ready(111)
		}.then { (value: Int) -> Promise<()> in
			sleep(1)
			if value == 111 {
				exp.fulfill()
			}
			return Promise(value: ())
	}