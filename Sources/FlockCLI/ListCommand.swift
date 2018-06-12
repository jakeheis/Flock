//
//  ListCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 3/28/18.
//

import PathKit
import SwiftCLI

class ListCommand: FlockCommand {
    
    let name = "list"
    let shortDescription = "List the available Flock tasks"
    
    func execute() throws {
        try guardFlockIsInitialized()
        
        stdout <<< ""
        stdout <<< "Tasks:"
        stdout <<< try Beak.generateTaskList()
        stdout <<< ""
    }
    
}
