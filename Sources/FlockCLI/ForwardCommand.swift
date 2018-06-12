//
//  ForwardCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import PathKit
import SwiftCLI

class ForwardCommand: FlockCommand {
    
    let name: String
    let shortDescription = ""
    
    let args = OptionalCollectedParameter()
    
    init(name: String) {
        self.name = name
    }
    
    func execute() throws {
        try guardFlockIsInitialized()
        try Beak.run(task: name, args: args.value)
    }
    
}
