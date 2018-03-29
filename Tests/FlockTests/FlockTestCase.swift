//
//  FlockTestCase.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import XCTest
@testable import Flock
import Shout
import Foundation

var testServer: Server? = {
    guard let serverIp = try? String(contentsOfFile: ".test-ip") else {
        return nil
    }
    return try? Server(ip: serverIp.trimmingCharacters(in: .whitespacesAndNewlines), user: "root", roles: [.app, .db, .web], authMethod: SSH.Key(
        privateKey: "~/.ssh/id_rsa"
    ))
}()

class FlockTestCase: XCTestCase {
    
    override func tearDown() {
        TestTaskMonitor.reset()
        
        TaskExecutor.setup(with: [])
        Server.servers = []
    }
    
}
