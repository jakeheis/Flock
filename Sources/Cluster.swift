//
//  Cluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import SwiftCLI

public protocol Cluster {
    var name: String { get }
    var tasks: [Task] { get }    
}

extension Cluster {
    public func taskToString(task: Task) -> String {
        return "\(name):\(task.name)"
    }
    
    public func keyTask(task: Task) -> KeyedTask {
        return KeyedTask(key: taskToString(task), task: task)
    }
}

extension Cluster {
    func keyedTasks() -> [KeyedTask] {
        return tasks.map { keyTask($0) }
    }
}
