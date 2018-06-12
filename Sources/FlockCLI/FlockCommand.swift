//
//  FlockCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import PathKit
import Rainbow
import SwiftCLI

protocol FlockCommand: Command {}

extension FlockCommand {
    
    var flockIsInitialized: Bool {
        return Beak.flockPath.exists
    }
    
    func guardFlockIsInitialized() throws {
        if !flockIsInitialized {
            throw FlockError(message: "Flock has not been initialized in this directory yet - run `flock init`")
        }
    }
    
}
