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

private struct InterruptPasser {
    static var process: Process? = nil
    
    static func setup(with process: Process) {
        self.process = process
        signal(SIGINT) { (sig) in
            InterruptPasser.process?.interrupt()
            signal(SIGINT, SIG_DFL)
            raise(SIGINT)
        }
    }
    
    static func restore() {
        signal(SIGINT, SIG_DFL)
    }
    
}

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
        
        InterruptPasser.setup(with: process)
        
        process.launch()
        process.waitUntilExit()
        
        InterruptPasser.restore()
        
        if process.terminationStatus != 0 {
            throw CLI.Error(message: "Error: ".red.bold + "Beak failed")
        }
    }
    
}
