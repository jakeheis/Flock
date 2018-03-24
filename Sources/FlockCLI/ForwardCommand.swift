//
//  ForwardCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import SwiftCLI
import PathKit

class ForwardCommand: FlockCommand {
    
    let name = ""
    let shortDescription = ""
    
    let optional = OptionalCollectedParameter()
    
    func execute() throws {
        try guardFlockIsInitialized()
        
        do {
            try SPM.build()
        } catch {
            throw CLI.Error(message: "Error: Flock must be successfully built before tasks can be run".red)
        }
        
        execv(Path.executable.description, CommandLine.unsafeArgv)
    }
    
}
