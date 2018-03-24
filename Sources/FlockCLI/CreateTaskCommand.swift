//
//  CreateTaskCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/27/16.
//
//

import SwiftCLI
import Rainbow
import PathKit

class CreateTaskCommand: FlockCommand {
    
    let name = "--create"
    let shortDescription = "Creates a task with the given name"
    
    let taskName = Parameter()
    
    let taskSuffix = "Task"
    
    public func execute() throws {
        var name = taskName.value
        if name.hasSuffix(taskSuffix) {
            name = String(name[..<name.index(name.endIndex, offsetBy: taskSuffix.count)])
        }
        
        let namespace: String?
        if let colonIndex = name.index(of: ":") {
            namespace = String(name[..<colonIndex])
            name = String(name[name.index(after: colonIndex)...])
        } else {
            namespace = nil
        }
        
        let namespaceSegment = namespace?.capitalized ?? ""
        let taskSegment = name.capitalized + taskSuffix
        let fileName = namespaceSegment + taskSegment + ".swift"
        let path = Path.deployDirectory + fileName
        if path.exists {
            throw CLI.Error(message: "\(path) already exists".red)
        }
        
        try write(contents: template(for: name, in: namespace), to: path)
        try createLink(at: Path.flockDirectory + fileName, pointingTo: ".." + path, logPath: path)
        
        print("What's left to do:".yellow)
        print("1. Replace <NameThisGroup> at the top of your new file with a custom name")
        print("2. In your Flockfile, add `Flock.use(WhateverINamedIt)`")
    }
    
    func template(for name: String, in namespace: String?) -> String {
        let taskName = name.capitalized + taskSuffix
        var lines = [
            "import Flock",
            "",
            "public extension TaskSource {",
            "   static let <NameThisGroup> = TaskSource(tasks: [",
            "       \(taskName)()",
            "   ])",
            "}",
            "",
            "// Delete if no custom Config properties are needed",
            "extension Config {",
            "   // public static var myVar = \"\"",
            "}",
            "",
            "class \(taskName): Task {",
            "   let name = \"\(name)\""
        ]
        if let namespace = namespace {
            lines.append("   let namespace = \"\(namespace)\"")
        }
        lines += [
            "",
            "   func run(on server: Server) throws {",
            "      // Do work",
            "   }",
            "}",
            ""
        ]
        return lines.joined(separator: "\n")
    }
    
}
