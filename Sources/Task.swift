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
    
    func run(server: ServerType) throws
}

extension Task {
  
    func internalRun(server: ServerType, key: String) throws {
        print("Task \(key) begun:".blue.bold)
        try run(server)
    }
  
}

enum TaskError: ErrorType {
    case CommandFailed
    case Error(String)
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
    case Before(String)
    case After(String)
}

extension ScheduleTime: Equatable {}
extension ScheduleTime: Hashable {
    public var hashValue: Int {
        switch self {
        case .Before(let task): return "before:\(task)".hashValue
        case .After(let task): return "after:\(task)".hashValue
        }
    }
}

public func == (lhs: ScheduleTime, rhs: ScheduleTime) -> Bool { 
  switch (lhs, rhs) {
    case let (.Before(t1), .Before(t2)) where t1 == t2: return true
    case let (.After(t1), .After(t2)) where t1 == t2: return true
    default: return false
  }
}
