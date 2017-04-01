//
//  ServerTests.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import XCTest
@testable import Flock

class TestCommandExecutor: ServerCommandExecutor {
    
    static var lastCall: String?
    
    let id = "test"
    
    func createArguments(for call: String) throws -> [String] {
        TestCommandExecutor.lastCall = call
        return ["/bin/bash", "-c", call]
    }
    
}

class ServerTests: FlockTestCase {
    
    static var allTests : [(String, (ServerTests) -> () throws -> Void)] {
        return [
            ("testExecute", testExecute),
            ("testCapture", testCapture),
            ("testWithin", testWithin),
            ("testFileExists", testFileExists),
            ("testDirectoryExists", testDirectoryExists),
            ("testUserServer", testUserServer),
            ("testHostServer", testHostServer),
            ("testDockerServer", testDockerServer),
            ("testDummyServer", testDummyServer)
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
    
    func testUserServer() {
        let userServer = UserServer(ip: "9.9.9.9", user: "root", authMethod: .key("/path/to/key"))
        
        guard let call = try? userServer.createArguments(for: "echo \"testUserServer\"") else {
            XCTFail()
            return
        }
        XCTAssert(call == ["/usr/bin/ssh", "-l", "root", "-i", "/path/to/key", "9.9.9.9", "echo \"testUserServer\""])
    }
    
    func testHostServer() {
        let hostServer = SSHHostServer(SSHHost: "MyHost")
        
        guard let call = try? hostServer.createArguments(for: "echo \"testHostServer\"") else {
            XCTFail()
            return
        }
        XCTAssert(call == ["/usr/bin/ssh", "MyHost", "echo \"testHostServer\""])
    }
    
    func testDockerServer() {
        let dockerServer = DockerServer(container: "my_container")
        
        guard let call = try? dockerServer.createArguments(for: "echo \"hello\"") else {
            XCTFail()
            return
        }
        XCTAssert(call == ["/usr/bin/env", "docker", "exec", "my_container", "bash", "/tmp/docker_call"])
    }
    
    func testDummyServer() {
        let dummyServer = DummyServer()
        
        guard let call = try? dummyServer.createArguments(for: "cat \"hello\"") else {
            XCTFail()
            return
        }
        XCTAssert(call == ["#"])
    }
    
}
