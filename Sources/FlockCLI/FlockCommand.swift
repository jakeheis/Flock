//
//  FlockCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import SwiftCLI
import PathKit
import Rainbow

protocol FlockCommand: Command {}

extension FlockCommand {
    
    var flockIsInitialized: Bool {
        return Path.flockfile.exists
    }
    
    func guardFlockIsInitialized() throws {
        if !flockIsInitialized {
            throw CLI.Error(message: "Error: ".red.bold + "Flock has not been initialized in this directory yet - run `flock --init`")
        }
    }
    
}
