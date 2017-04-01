//
//  TaskExecutorTests.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import XCTest
@testable import Flock

class TaskExecutorTests: FlockTestCase {
    
    static var allTests : [(String, (TaskExecutorTests) -> () throws -> Void)] {
        return [
            ("testTask", testTask),
            ("testNamedTask", testNamedTask),
            ("testHookedTasks", testHookedTasks),
            ("testNoServers", testNoServers),
            ("testRoleExecution", testRoleExecution)
        ]
    }
    
    override func setUp() {
        TaskExecutor.setup(with: TestTasks)
    }
    
    func testTask() {
        Servers.add(ip: "9.9.9.9", user: "root", roles: [.app, .db, .web])

        do {
            try TaskExecutor.run(task: TestTasks[1])
        } catch {
            XCTFail(String(describing: error))
            return
        }
        
        XCTAssert(TestTaskMonitor.firstExecuted == false)
        XCTAssert(TestTaskMonitor.secondExecuted == true)
        XCTAssert(TestTaskMonitor.thirdExecuted == false)
        XCTAssert(TestTaskMonitor.output == "<second on root@9.9.9.9>")
    }
    
    func testNamedTask() {
        Servers.add(ip: "9.9.9.9", user: "root", roles: [.app, .db, .web])

        do {
            try TaskExecutor.run(taskNamed: "test:first")
        } catch {
            XCTFail(String(describing: error))
            return
        }
        
        XCTAssert(TestTaskMonitor.firstExecuted == true)
        XCTAssert(TestTaskMonitor.secondExecuted == false)
        XCTAssert(TestTaskMonitor.thirdExecuted == false)
        XCTAssert(TestTaskMonitor.output == "<first on root@9.9.9.9>")
    }
    
    func testHookedTasks() {
        Servers.add(ip: "9.9.9.9", user: "root", roles: [.app, .db, .web])

        do {
            try TaskExecutor.run(task: TestTasks[2])
        } catch {
            XCTFail(String(describing: error))
            return
        }
        
        XCTAssert(TestTaskMonitor.firstExecuted == true)
        XCTAssert(TestTaskMonitor.secondExecuted == true)
        XCTAssert(TestTaskMonitor.thirdExecuted == true)
        XCTAssert(TestTaskMonitor.output == "<first on root@9.9.9.9><third on root@9.9.9.9><second on root@9.9.9.9>")
    }
    
    func testNoServers() {
        do {
            try TaskExecutor.run(task: TestTasks[2])
            XCTFail() // Should throw an error since there are no servers
        } catch {}
    }
    
    func testRoleExecution() {
        Servers.add(ip: "8.8.8.8", user: "root", roles: [.app])
        Servers.add(ip: "9.9.9.9", user: "root", roles: [.db])
        
        do {
            try TaskExecutor.run(task: TestTasks[0])
        } catch {
            XCTFail(String(describing: error))
            return
        }
        XCTAssert(TestTaskMonitor.firstExecuted == true)
        XCTAssert(TestTaskMonitor.secondExecuted == false)
        XCTAssert(TestTaskMonitor.thirdExecuted == false)
        XCTAssert(TestTaskMonitor.output == "<first on root@8.8.8.8><first on root@9.9.9.9>")
        TestTaskMonitor.reset()
        
        do {
            try TaskExecutor.run(task: TestTasks[1])
        } catch {
            XCTFail(String(describing: error))
            return
        }
        XCTAssert(TestTaskMonitor.firstExecuted == false)
        XCTAssert(TestTaskMonitor.secondExecuted == true)
        XCTAssert(TestTaskMonitor.thirdExecuted == false)
        XCTAssert(TestTaskMonitor.output == "<second on root@8.8.8.8>")
        TestTaskMonitor.reset()
        
        do {
            try TaskExecutor.run(task: TestTasks[2])
        } catch {
            XCTFail(String(describing: error))
            return
        }
        XCTAssert(TestTaskMonitor.firstExecuted == true)
        XCTAssert(TestTaskMonitor.secondExecuted == true)
        XCTAssert(TestTaskMonitor.thirdExecuted == true)
        XCTAssert(TestTaskMonitor.output == "<first on root@8.8.8.8><first on root@9.9.9.9><third on root@9.9.9.9><second on root@8.8.8.8>")
    }
    
}
