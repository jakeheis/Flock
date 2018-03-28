//
//  ForwardCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import SwiftCLI

class ForwardCommand: FlockCommand {
    
    let name = ""
    let shortDescription = ""
    
    let args = CollectedParameter()
    
    func execute() throws {
        try guardFlockIsInitialized()
        
        do {
            try executeBeak(args: ["run", "--path", "Flock.swift"] + args.value)
        } catch {}
    }
    
}
