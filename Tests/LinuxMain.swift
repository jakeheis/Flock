import XCTest
@testable import FlockTests

XCTMain([
	 testCase(ServerTests.allTests),
	 testCase(TaskExecutorTests.allTests),
	 testCase(TaskScheulerTests.allTests)
])
