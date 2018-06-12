//
//  CheckCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 6/11/18.
//

import Rainbow
import SwiftCLI

class CheckCommand: FlockCommand {
    
    let name = "check"
    let shortDescription = "Check that your Flock.swift can be compiled and run"
    
    func execute() throws {
        try Beak.run(task: nil, args: [])
        stdout <<< "Success!".green.bold
    }
    
}
