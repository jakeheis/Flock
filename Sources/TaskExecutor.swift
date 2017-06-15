//
//  TaskExecutor.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

class TaskExecutor {
    
    private static var tasks: [Task] = []
    private static var scheduler: TaskScheduler?
    
    static func setup(with tasks: [Task]) {
        self.tasks = tasks
        self.scheduler = TaskScheduler(tasks: tasks)
    }
    
    static func run(task: Task, on server: Server? = nil) throws {
        try runTasks(scheduled: .before(task.fullName))
        
        if Server.servers.isEmpty {
            throw TaskError(message: "You must specify servers in your configuration files")
        }
        
        Logger.logTaskBegun(task)
        
        if let server = server {
            try task.run(on: server)
        } else {
            let taskRoles = Set(task.serverRoles)
            for server in Server.servers where !Set(server.roles).isDisjoint(with: taskRoles) {
                try task.run(on: server)
            }
        }
        
        try runTasks(scheduled: .after(task.fullName))
    }
    
    static func run(taskNamed name: String, on server: Server? = nil) throws {
        guard let task = tasks.first(where: { $0.fullName == name }) else {
            throw TaskError(message: "Task \(name) not found")
        }
        try run(task: task, on: server)
    }
    
    // MARK: - Private
    
    private static func runTasks(scheduled scheduleTime: HookTime) throws {
        let taskNames = scheduler!.scheduledTasks(at: scheduleTime)
        for name in taskNames {
            try run(taskNamed: name)
        }
    }
    
}
