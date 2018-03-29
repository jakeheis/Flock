//
//  Beak.swift
//  FlockPackageDescription
//
//  Created by Jake Heiser on 3/28/18.
//

import BeakCore
import SwiftCLI

struct Beak {
    
    static func execute(args: [String]) throws {
        let options = BeakOptions(cachePath: "/tmp/flock/builds")
        let beak = BeakCore.Beak(options: options)
        do {
            try beak.execute(arguments: args)
        } catch let error {
            throw CLI.Error(message: "Error: ".red.bold + error.localizedDescription + " (Beak failure)")
        }
    }
    
    private init() {}
    
}
