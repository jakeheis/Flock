//
//  TaskScheduler.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

class TaskScheduler {
    
    private var schedule: [HookTime: [String]] = [:]
    
    init(tasks: [Task]) {
        self.schedule(tasks: tasks)
    }
    
    func schedule(tasks: [Task]) {
        for task in tasks {
            for time in task.hookTimes {
                var timeTasks = schedule[time] ?? []
                timeTasks.append(task.fullName)
                schedule[time] = timeTasks
            }
        }
    }
  
    func scheduledTasks(at time: HookTime) -> [String] {
        return schedule[time] ?? []
    }
  
}
