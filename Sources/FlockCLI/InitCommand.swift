//
//  InitCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import Foundation
import SwiftCLI
import Rainbow
import PathKit
import Spawn

class InitCommand: FlockCommand {
  
    let name = "init"
    let shortDescription = "Initializes Flock in the current directory"
    
    func execute() throws {
        guard !flockIsInitialized else {
            throw CLI.Error(message: "Error: ".red + "Flock has already been initialized")
        }
        
        try Path.flockfile.write("""
        public func deploy() {
            print("deploying")
        }

        """)
    }
    
}
