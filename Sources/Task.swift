//
//  Task.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

public protocol Task {
    var name: String { get }
    var taskTimes: [TaskTime] { get }
    
    func run()
}

public enum TaskTime {
    case Before(String)
    case After(String)
}

extension Task {
    var taskTimes = []
}
