//
//  TaskScheulerTests.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import XCTest
@testable import Flock

class TaskScheulerTests: FlockTestCase {
  
    static var allTests : [(String, (TaskScheulerTests) -> () throws -> Void)] {
        return [
            ("testSchedule", testSchedule)
        ]
    }
    
    func testSchedule() {
        let scheduler = TaskScheduler(tasks: TestTasks)
        
        XCTAssert(scheduler.scheduledTasks(at: .before("test:first")).count == 0)
        XCTAssert(scheduler.scheduledTasks(at: .before("test:third")) == ["test:first"])
        XCTAssert(scheduler.scheduledTasks(at: .after("test:first")).count == 0)
        XCTAssert(scheduler.scheduledTasks(at: .after("test:third")) == ["test:second"])
    }

}
