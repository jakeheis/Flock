//
//  Task.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

// MARK: - Task

public protocol Task {
    var name: String { get }
    var serverRoles: [ServerRole] { get }
    
    func run(on server: Server) throws
}

extension Task {
    
    public var serverRoles: [ServerRole] { return [.app, .db, .web]}
  
    func internalRun(on server: Server, key: String) throws {
        print("Task \(key) begun:".blue.bold)
        try run(on: server)
    }
  
}

enum TaskError: Error {
    case commandFailed
    case error(String)
}

// MARK: - KeyedTask

struct KeyedTask {
    let key: String
    let task: Task
}

// MARK: - ScheduledTask

public protocol ScheduledTask: Task {
    var scheduledTimes: [ScheduleTime] { get }
}

public enum ScheduleTime {
    case before(String)
    case after(String)
}

extension ScheduleTime: Equatable {}
extension ScheduleTime: Hashable {
    public var hashValue: Int {
        switch self {
        case .before(let task): return "before:\(task)".hashValue
        case .after(let task): return "after:\(task)".hashValue
        }
    }
}

public func == (lhs: ScheduleTime, rhs: ScheduleTime) -> Bool { 
  switch (lhs, rhs) {
    case let (.before(t1), .before(t2)) where t1 == t2: return true
    case let (.after(t1), .after(t2)) where t1 == t2: return true
    default: return false
  }
}
