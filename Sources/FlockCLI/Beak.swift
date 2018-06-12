//
//  Beak.swift
//  FlockPackageDescription
//
//  Created by Jake Heiser on 3/28/18.
//

import BeakCore
import PathKit
import SwiftCLI

struct Beak {
    
    static let flockPath = Path("Flock.swift")
    private static let cachePath = Path("~/.beak/flock/builds").normalize()
    
    static func run(task: String? = nil, args: [String] = []) throws {
        let flockfile = try BeakFile(path: flockPath)
        
        var functionCall: String?
        if let task = task {
            guard let function = flockfile.functions.first(where: { $0.name == task }) else {
                throw BeakError.invalidFunction(task)
            }
            functionCall = try FunctionParser.getFunctionCall(function: function, arguments: args)
        }
        
        // create package
        let directory = flockPath.absolute().parent()
        let packagePath = cachePath + directory.string.replacingOccurrences(of: "/", with: "_")
        let productName = "Flockfile"
        let packageManager = PackageManager(path: packagePath, name: productName, beakFile: flockfile)
        try packageManager.write(functionCall: functionCall)
        
        do {
            _ = try capture("swift", arguments: ["build", "--disable-sandbox"], directory: packagePath.string)
        } catch let error as CaptureError {
            WriteStream.stderr <<< error.captured.rawStdout
            WriteStream.stderr <<< error.captured.rawStderr
            throw error
        }
        
        let executable = "\(packagePath.string)/.build/debug/\(productName)"
        if task != nil {
            try Task.execvp(executable, arguments: [])
        } else {
            try SwiftCLI.run(executable)
        }
    }
    
    static func cleanBuilds() throws {
        let directory = flockPath.absolute().parent()
        let packagePath = cachePath + directory.string.replacingOccurrences(of: "/", with: "_")
        try packagePath.delete()
    }
    
    static func findTasks() throws -> [Function] {
        let beak = try BeakFile(path: flockPath)
        return beak.functions
    }
    
    static func generateTaskList() throws -> String {
        let tasks = try findTasks()
        
        let spacingLength = tasks.reduce(into: 12, { (length, task) in
            length = max(task.name.count + 4, length)
        })
        
        return tasks.map({ (task) -> String in
            let spacing = String(repeating: " ", count: spacingLength - task.name.count)
            var line = "  \(task.name)"
            if let docsDescription = task.docsDescription {
                line += "\(spacing)\(docsDescription)"
            }
            return line
        }).joined(separator: "\n")
    }
    
    private init() {}
    
}
