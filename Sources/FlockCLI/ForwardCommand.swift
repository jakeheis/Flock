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

import Foundation
import SwiftCLI
import PathKit

class ForwardCommand: FlockCommand {
    
    let name = ""
    let shortDescription = ""
    
    let args = CollectedParameter()
    
    func execute() throws {
        try guardFlockIsInitialized()
        
//        do {
//            try SPM.build()
//        } catch {
//            throw CLI.Error(message: "Error: Flock must be successfully built before tasks can be run".red)
//        }
//
//        execv(Path.executable.description, CommandLine.unsafeArgv)
        
        let p = Process()
        p.launchPath = "/usr/local/bin/beak"
        p.arguments = ["run", "--path", "Flock.swift"] + args.value
        p.launch()
        p.waitUntilExit()
        
//        let swiftArgs = ["beak", "run", "--path", ]
        
//        execvp(<#T##__file: UnsafePointer<Int8>!##UnsafePointer<Int8>!#>, <#T##__argv: UnsafePointer<UnsafeMutablePointer<Int8>?>!##UnsafePointer<UnsafeMutablePointer<Int8>?>!#>)
    }
    
}
