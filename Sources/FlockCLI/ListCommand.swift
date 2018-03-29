//
//  ListCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 3/28/18.
//

import SwiftCLI

class ListCommand: FlockCommand {
    
    let name = "list"
    let shortDescription = "List the available Flock tasks"
    
    func execute() throws {
        guard flockIsInitialized else {
            throw CLI.Error(message: "Error: ".red.bold + "Flock has not been initialized")
        }
        
        try Beak.execute(args: ["list", "--path", "Flock.swift"])
    }
    
}
