//
//  CleanCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 3/29/18.
//

import Foundation

class CleanCommand: FlockCommand {
    
    let name = "clean"
    let shortDescription = "Clean the Flock build directory"
    
    func execute() throws {
        try guardFlockIsInitialized()
        try Beak.cleanBuilds()
    }
    
}
