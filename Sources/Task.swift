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
    var namespace: String { get }
    
    var serverRoles: [ServerRole] { get }
    var hookTimes: [HookTime] { get }
    
    func run(on server: Server) throws
}

public extension Task {
    
    var serverRoles: [ServerRole] {
        return [.app, .db, .web]
    }
    
    var hookTimes: [HookTime] {
        return []
    }
    
    var fullName: String {
        if !namespace.isEmpty {
            return namespace + ":" + name
        }
        return name
    }
    
    var namespace: String {
        return ""
    }
    
    func invoke(_ name: String, on server: Server) throws {
        try TaskExecutor.run(taskNamed: name, on: server)
    }
    
}

// MARK: - TaskError

public struct TaskError: Error {
    
    public let message: String
    public var commandSuggestion: String?
    
    public init(status: Int32, commandSuggestion: String? = nil) {
        self.init(message: "a command failed (error \(status))", commandSuggestion: commandSuggestion)
    }
    
    public init(message: String, commandSuggestion: String? = nil) {
        self.message = message
        self.commandSuggestion = commandSuggestion
    }
    
    public func output() {
        print()
        print("Error: ".red + message)
        if let commandSuggestion = commandSuggestion {
            print("Try running: ".yellow + commandSuggestion)
        }
        print()
    }
    
}

// MARK: - HookTime

public enum HookTime {
    case before(String)
    case after(String)
}

extension HookTime: Equatable {}
extension HookTime: Hashable {
    public var hashValue: Int {
        switch self {
        case let .before(task): return "before:\(task)".hashValue
        case let .after(task): return "after:\(task)".hashValue
        }
    }
}

public func == (lhs: HookTime, rhs: HookTime) -> Bool {
    switch (lhs, rhs) {
    case let (.before(t1), .before(t2)) where t1 == t2: return true
    case let (.after(t1), .after(t2)) where t1 == t2: return true
    default: return false
    }
}
