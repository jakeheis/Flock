//
//  DeployTests.swift
//  Flock
//
//  Created by Jake Heiser on 4/2/17.
//
//

import XCTest
@testable import Flock

class DeployTests: FlockTestCase {
    
    func testTasks() {
        guard let testServer = testServer else {
            print("Skipping DeployTests (Docker server not running)")
            return
        }
        
        Config.deployDirectory = "/var/www"
        Config.projectName = "TestProject"
        Config.repoURL = "/tmp/TestProject"
        
        git(testServer)
        build(testServer)
        link(testServer)
    }
    
    func git(_ testServer: Server) {
        XCTAssert(!testServer.directoryExists("/var/www"))
        
        let git = GitTask()
        do {
            try git.run(on: testServer)
        } catch let error {
            XCTFail("Git task should succeed; failed with \(error)")
            return
        }
        
        XCTAssert(testServer.directoryExists("/var/www/TestProject"))
        XCTAssert(testServer.directoryExists("/var/www/TestProject/next"))
        XCTAssert(testServer.directoryExists("/var/www/TestProject/releases"))
    }
    
    func build(_ testServer: Server) {
        XCTAssert(!testServer.fileExists("/var/www/TestProject/next/.build/release/TestProject"))
        
        let git = BuildTask()
        do {
            try git.run(on: testServer)
        } catch let error {
            XCTFail("Build task should succeed; failed with \(error)")
            return
        }
        
        XCTAssert(testServer.fileExists("/var/www/TestProject/next/.build/release/TestProject"))
    }
    
    func link(_ testServer: Server) {
        XCTAssert(!testServer.directoryExists("/var/www/TestProject/current"))
        
        let git = LinkTask()
        do {
            try git.run(on: testServer)
        } catch let error {
            XCTFail("Link task should succeed; failed with \(error)")
            return
        }
        
        XCTAssert(testServer.directoryExists("/var/www/TestProject/current"))
    }
    
}
