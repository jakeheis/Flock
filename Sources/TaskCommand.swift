//
//  TaskCommand.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import SwiftCLI

class TaskCommand: Command {
    
    let name: String
    let task: Task
    
    let dryRun = Flag("-n", "--none")
    let environment = Key<String>("-e", "--enviornment")
    
    init(task: Task) {
        self.name = task.fullName
        self.task = task
    }
    
    func execute() throws {
        Flock.setup(for: (environment.value ?? "production"))
        
        TaskExecutor.mode = dryRun.value ? .dryRun : .execute
        
        do {
            try TaskExecutor.run(task: task)
        } catch TaskError.commandFailed {
            throw CLIError.error("A command failed.".red)
        } catch TaskError.error(let string) {
            throw CLIError.error(string.red)
        } catch let error {
            throw error
        }
    }
  
}
