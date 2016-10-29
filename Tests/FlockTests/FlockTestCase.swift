//
//  FlockTestCase.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import XCTest
@testable import Flock

class FlockTestCase: XCTestCase {
    
    override func tearDown() {
        TestTaskMonitor.reset()
        
        TaskExecutor.setup(with: [])
        Servers.servers = []
    }
    
}
