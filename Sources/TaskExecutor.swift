//
//  TaskExecutor.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

class TaskExecutor {
  
    enum Mode {
        case execute
        case dryRun
    }
    
    private static var tasks: [Task] = []
    private static var scheduler: TaskScheduler?
    
    static var mode: Mode = .execute
    
    static func setup(with tasks: [Task]) {
        self.tasks = tasks
        self.scheduler = TaskScheduler(tasks: tasks)
    }
    
    static func run(task: Task) throws {
        try runTasks(scheduled: .before(task.fullName))
        
        if Servers.servers.isEmpty && mode == .execute {
            throw TaskError.error("You must specify servers in your configuration files")
        }
        
        Logger.logTaskBegun(task)
        
        switch mode {
        case .execute:
            for server in Servers.servers {
                if Set(server.roles).isDisjoint(with: Set(task.serverRoles)) {
                    continue
                }
                try task.run(on: server)
            }
        case .dryRun:
            do {
                try task.run(on: Server.createDummyServer())
            } catch {}
        }
        
        try runTasks(scheduled: .after(task.fullName))
    }
    
    static func run(taskNamed name: String) throws {
        guard let task = tasks.first(where: { $0.fullName == name }) else {
            throw TaskError.error("Task \(name) not found")
        }
        try run(task: task)
    }
    
    // MARK: - Private
    
    private static func runTasks(scheduled scheduleTime: HookTime) throws {
        guard let scheduler = scheduler else {
            throw TaskError.error("Something went very very wrong")
        }
        let taskNames = scheduler.scheduledTasks(at: scheduleTime)
        for name in taskNames {
            try run(taskNamed: name)
        }
    }
    
}
