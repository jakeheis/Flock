//
//  ServerTests.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import XCTest
import Spawn
@testable import Flock

class TestCommandExecutor: ServerCommandExecutor {
    
    static var lastCall: String?
    
    let id = "test"
    
    func execute(_ call: String, capture: Bool, matchers: [OutputMatcher]?) throws -> String? {
        var captured = ""
        let spawned = try Spawn(args: ["/bin/bash", "-c", call], output: { (output) in
            if capture {
                captured += output
            } else {
                print(output, terminator: "")
            }
            fflush(stdout)
            matchers?.forEach { $0.match(output) }
        })
        
        guard spawned.waitForExit() == 0 else {
            throw TaskError.commandFailed
        }
        return capture ? captured : nil
    }
    
}

class ServerTests: FlockTestCase {
    
    static var allTests : [(String, (ServerTests) -> () throws -> Void)] {
        return [
            ("testExecute", testExecute),
            ("testCapture", testCapture),
            ("testWithin", testWithin),
            ("testFileExists", testFileExists),
            ("testDirectoryExists", testDirectoryExists)
        ]
    }
    
    func testExecute() {
        let server = Server(commandExecutor: TestCommandExecutor(), roles: [.app])
        
        do {
            try server.execute("echo \"testExecute\"")
        } catch {
            XCTFail()
        }
        
        XCTAssert(TestCommandExecutor.lastCall == "echo \"testExecute\"")
    }
    
    func testCapture() {
        let server = Server(commandExecutor: TestCommandExecutor(), roles: [.app])
        
        do {
            let output = try server.capture("echo \"testCapture\"")
            XCTAssert(output == "testCapture\n")
        } catch {
            XCTFail()
        }
        
        XCTAssert(TestCommandExecutor.lastCall == "echo \"testCapture\"")
    }
  
    func testWithin() {
        let server = Server(commandExecutor: TestCommandExecutor(), roles: [.app])
        
        do {
            try server.within("within_me") {
                try server.execute("echo \"testWithin\"")
            }
        } catch {
            XCTFail()
        }
        
        XCTAssert(TestCommandExecutor.lastCall == "cd within_me; echo \"testWithin\"")
    }
    
    func testFileExists() {
        let server = Server(commandExecutor: TestCommandExecutor(), roles: [.app])
        
        let exists = server.fileExists("/bin/cat")
        XCTAssert(exists == true)
        XCTAssert(TestCommandExecutor.lastCall == "test -f /bin/cat")
    }
    
    func testDirectoryExists() {
        let server = Server(commandExecutor: TestCommandExecutor(), roles: [.app])
        
        let exists = server.directoryExists("/bin")
        XCTAssert(exists == true)
        XCTAssert(TestCommandExecutor.lastCall == "test -d /bin")
    }
    
}
