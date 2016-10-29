//
//  TaskCommand.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import SwiftCLI

class TaskCommand: OptionCommand {
  
    let name: String
    let signature = ""
    let shortDescription = ""
    
    let task: Task
    
    private var mode: TaskExecutor.Mode = .execute
    private var environment = "production"
  
    init(task: Task) {
        self.name = task.fullName
        self.task = task
    }
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-n", "--none"]) {
            self.mode = .dryRun
        }
        options.add(keys: ["-e", "--enviornment"]) { (value) in
            self.environment = value
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        Flock.configure(for: environment)
        
        TaskExecutor.mode = mode
        
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
