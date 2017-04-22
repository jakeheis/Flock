//
//  FlockTestCase.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import XCTest
@testable import Flock

var testServer: Server? = {
    guard let containerId = try? String(contentsOfFile: ".test-docker-id") else {
        return nil
    }
    return Server(dockerContainer: containerId.trimmingCharacters(in: .whitespacesAndNewlines), roles: [.app, .db, .web])
}()

class FlockTestCase: XCTestCase {
    
    override func tearDown() {
        TestTaskMonitor.reset()
        
        TaskExecutor.setup(with: [])
        Servers.servers = []
    }
    
}
