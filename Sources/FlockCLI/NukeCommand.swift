//
//  NukeCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 6/5/17.
//

import SwiftCLI
import PathKit

class NukeCommand: Command {
    
    let name = "--nuke"
    let shortDescription = "Deletes Flock files in the current project"
    
    func execute() throws {
        stdout <<< "Are you sure you want to remove all Flock files from this project?"
        if Input.readBool(prompt: "> ") {
            if Path.flockDirectory.exists {
                try Path.flockDirectory.delete()
            }
            if Path.flockfile.exists {
                try Path.flockfile.delete()
            }
            if Path.deployDirectory.exists {
                try Path.deployDirectory.delete()
            }
        }
    }
    
}
