//
//  Cluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

// MARK: - Cluster

public protocol Cluster {
    var name: String { get }
    var tasks: [Task] { get }
}

extension Cluster {
    public func taskToString(task: Task) -> String {
        return "\(name):\(task.name)"
    }
}

// MARK: - KeyedTask extension

extension Cluster {
    func keyedTasks() -> [KeyedTask] {
        return tasks.map { KeyedTask(key: taskToString($0), task: $0) }
    }
}
