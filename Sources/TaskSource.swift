//
//  TaskSource.swift
//  Flock
//
//  Created by Jake Heiser on 4/2/17.
//
//

public class TaskSource {
    
    let tasks: [Task]
    var beingUsed = false
    
    init(tasks: [Task]) {
        self.tasks = tasks
    }
    
}
