//
//  FlockHelpMessageGenerator.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/28/16.
//
//

import Foundation
import SwiftCLI

class FlockHelpMessageGenerator: HelpMessageGenerator {
    
    func generateCommandList(for path: CommandGroupPath) -> String {
        var list = DefaultHelpMessageGenerator().generateCommandList(for: path)
        
        let pipe = Pipe()
        
        let p = Process()
        p.launchPath = "/usr/local/bin/beak"
        p.arguments = ["list", "--path", "Flock.swift"]
        p.standardOutput = pipe
        p.launch()
        p.waitUntilExit()
        
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        
        list += "\n" + output.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        
        return list
    }
    
}

/*
class HelpCommand: FlockCommand {
    
    let name = "help"
    let shortDescription = "Prints help information"
    
    let cli: CLI
    
    init(cli: CLI) {
        self.cli = cli
    }
        
    func execute() throws {
        print("Available commands: ")
        
        printLine(name: "<task>", description: "Execute the given task")
        
        for command in cli.children.flatMap({ $0 as? Command }) {
            let path = CommandGroupPath(cli: cli).appending(command)
            printLine(name: path.joined(), description: command.shortDescription)
        }
        
        if flockIsInitialized {
            print()
            
            if Path.executable.exists {
                // Forward to help command of local cli
                let spawn = try Spawn(args: [Path.executable.description, "--print-tasks"]) { (chunk) in
                    print(chunk, terminator: "")
                }
                _ = spawn.waitForExit()
            } else {
                print("Local Flock not built; run `flock --build` then `flock` to see available tasks")
            }
        }
    }
    
    private func printLine(name: String, description: String) {
        let spacing = String(repeating: " ", count: 20 - name.count)
        print("flock \(name)\(spacing)\(description)")
    }
    
}
*/
