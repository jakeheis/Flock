//
//  FlockCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import Foundation
import PathKit
import Rainbow
import SwiftCLI

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
    
    func executeBeak(args: [String]) throws {
        let process = Process()
        process.launchPath = "/usr/local/bin/beak"
        process.arguments = args
        process.launch()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw CLI.Error(message: "Error: ".red.bold + "Beak failed")
        }
    }
    
}
