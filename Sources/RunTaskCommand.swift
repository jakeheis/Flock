//
//  RunTaskCommand.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation

class RunTaskCommand: CommandType {
    
    let commandName = ""
    let commandSignature = "<execute>"
    let commandShortDescription = ""
    
    var groups: [Group] = []
    
    func execute(arguments: CommandArguments) throws {
        let execute = arguments.requiredArgument("execute")
        
        var group: String
        var task: String?
        
        if let colonIndex = execute.characters.indexOf(":") {
            group = execute.substringToIndex(colonIndex)
            task = execute.substringFromIndex(colonIndex.successor())
        } else {
            group = execute
        }
        
        try runGroup(group, singleTask: task)
    }
    
    func loadGroups() {
        
    }
    
    func runGroup(group: String, singleTask: String?) throws {
        guard let group = groups.filter({ $0.name == group }).first else {
            throw CLIError.Error("Task group not found")
        }
        
        if let singleTask = singleTask {
            guard let task = group.tasks.filter({ $0.name == singleTask }).first else {
                throw CLIError.Error("Task not found")
            }
            runTask(task)
        } else {
            for task in group.tasks {
                runTask(task)
            }
        }
    }
    
    func runTask(task: Task) {
        task.run()
    }
    
}
