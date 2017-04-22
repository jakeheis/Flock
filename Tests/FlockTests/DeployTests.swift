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
    
    func testGit() {
        guard let testServer = testServer else {
            print("Skipping DeployTests (Docker server not running)")
            return
        }
        
        Config.projectName = "TestProject"
        Config.repoURL = "/tmp/TestProject"
        
        let git = GitTask()
        do {
            try git.run(on: testServer)
        } catch let error {
            XCTFail("Git task should succeed; failed with \(error)")
        }
    }
    
}
