//
//  TaskError.swift
//  FlockTests
//
//  Created by Jake Heiser on 3/29/18.
//

public struct TaskError: Error {
    
    public let message: String
    
    public init(status: Int32) {
        self.init(message: "a command failed (code: \(status))")
    }
    
    public init(message: String) {
        self.message = message
    }
    
    public func output() {
        print()
        print("Error: ".red.bold + message)
        print()
    }
    
}
