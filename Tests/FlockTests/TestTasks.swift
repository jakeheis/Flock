//
//  TestTasks.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import Foundation
@testable import Flock

class TestTaskMonitor {
    
    static var firstExecuted = false
    static var secondExecuted = false
    static var thirdExecuted = false
    
    static var output = ""
    
    static func reset() {
        firstExecuted = false
        secondExecuted = false
        thirdExecuted = false
        output = ""
    }
    
}

let TestTasks: [Task] = [FirstTestTask(), SecondTestTask(), ThirdTestTask()]

class FirstTestTask: Task {
    
    let name = "first"
    let namespace = "test"
    let hookTimes: [HookTime] = [.before("test:third")]
    let serverRoles: [ServerRole] = [.app, .db, .web]
    
    func run(on server: Server) throws {
        TestTaskMonitor.firstExecuted = true
        TestTaskMonitor.output += "<first on \(server)>"
    }
    
}

class SecondTestTask: Task {
    
    let name = "second"
    let namespace = "test"
    let hookTimes: [HookTime] = [.after("test:third")]
    let serverRoles: [ServerRole] = [.app]
    
    func run(on server: Server) throws {
        TestTaskMonitor.secondExecuted = true
        TestTaskMonitor.output += "<second on \(server)>"
    }
    
}

class ThirdTestTask: Task {
    
    let name = "third"
    let namespace = "test"
    let serverRoles: [ServerRole] = [.db]
    
    func run(on server: Server) throws {
        TestTaskMonitor.thirdExecuted = true
        TestTaskMonitor.output += "<third on \(server)>"
    }
    
}
