//
//  FlockError.swift
//  FlockCLI
//
//  Created by Jake Heiser on 3/30/18.
//

import Rainbow
import SwiftCLI

struct FlockError: ProcessError {
    
    public let message: String?
    public let exitStatus: Int32 = 1
    
    init(message: String) {
        self.message = "Error: ".red.bold + message
    }
    
}
