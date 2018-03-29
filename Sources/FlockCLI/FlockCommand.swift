//
//  FlockCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import Foundation
import Rainbow
import SwiftCLI
import BeakCore

protocol FlockCommand: Command {}

extension FlockCommand {
    
    var flockPath: String {
        return "Flock.swift"
    }
    
    var flockIsInitialized: Bool {
        return FileManager.default.fileExists(atPath: flockPath)
    }
    
    func guardFlockIsInitialized() throws {
        if !flockIsInitialized {
            throw CLI.Error(message: "Error: ".red.bold + "Flock has not been initialized in this directory yet - run `flock --init`")
        }
    }
    
}
