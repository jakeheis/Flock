//
//  Logger.swift
//  Flock
//
//  Created by Jake Heiser on 10/24/16.
//
//

class Logger {
    
    private init() {}
    
//    static func logTaskBegun(_ task: Task) {
//        print("Task \(task.fullName) begun:".blue.bold)
//    }
    
    static func logCall(_ call: String, on server: Server) {
        print("On \(server): \(call)".green)
    }
    
}
