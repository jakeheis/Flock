//
//  HelpCommand.swift
//  Flock
//
//  Created by Jake Heiser on 10/28/16.
//
//

import SwiftCLI

class HelpCommand: SwiftCLI.HelpCommand {
    
    let name = "--help"
    let signature = "[<opt>] ..."
    let shortDescription = "Prints help information"
    
    let failOnUnrecognizedOptions = false
    let unrecognizedOptionsPrintingBehavior = UnrecognizedOptionsPrintingBehavior.printNone
    let helpOnHFlag = false
    
    var allCommands: [Command] = []
    var printCLIDescription = true
    
    func setupOptions(options: OptionRegistry) {}
    
    func execute(arguments: CommandArguments) throws {
        print("Available tasks:")
        for task in Flock.tasks {
            print("flock \(task.fullName)")
        }
        print()
        print("To print help information: flock --help")
    }
    
}

// This will never actually be invoked
class VersionCommand: Command {
    
    let name = "--version"
    let signature = ""
    let shortDescription = ""
    
    func execute(arguments: CommandArguments) throws {}
    
}
