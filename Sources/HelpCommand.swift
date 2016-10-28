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
        
        if printCLIDescription {
            print("Task options:")
            printOption("-e <env>", description: "Run in the given environment; default `production`")
            printOption("-n", description: "Dry run -- dont actually execute any commands")
            print()
        }
        
        print("To print help information: flock --help")
    }
    
    func printOption(_ option: String, description: String) {
        let spacing = String(repeating: " ", count: 15 - option.characters.count)
        print("\(option)\(spacing)\(description)")
    }
    
}

// This will never actually be invoked
class VersionCommand: Command {
    
    let name = "--version"
    let signature = ""
    let shortDescription = ""
    
    func execute(arguments: CommandArguments) throws {}
    
}
