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

public struct Config {}

extension Cluster {
    
    func taskToString(_ task: Task) -> String {
        return "\(name):\(task.name)"
    }
    
    func task(named taskName: String) -> KeyedTask? {
        return keyedTasks().first(where: { $0.task.name == taskName })
    }
    
}

// MARK: - KeyedTask extension

extension Cluster {
    func keyedTasks() -> [KeyedTask] {
        return tasks.map { KeyedTask(key: taskToString($0), task: $0) }
    }
}
