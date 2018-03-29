//
//  SwiftenvTasks.swift
//  Flock
//
//  Created by Jake Heiser on 4/27/17.
//
//
/*
public extension TaskSource {
    static let swiftenv = TaskSource(tasks: [
        SwiftInstallTask()
    ])
}

public extension Config {
    static var swiftenvLocation = "~/.swiftenv"
    static var swiftVersion: String? = nil
}

class SwiftInstallTask: Task {
    
    let name = "install"
    let namespace = "swiftenv"
    let hookTimes: [HookTime] = [.before("deploy:build")]
    
    func run(on server: Server) throws {
        let swiftenvExecutable: String
        if server.commandExists("swiftenv") {
            swiftenvExecutable = "swiftenv"
        } else if server.directoryExists(Config.swiftenvLocation) {
            swiftenvExecutable = Config.swiftenvLocation + "/bin/swiftenv"
        } else {
            throw TaskError(message: "swiftenv not found at path \(Config.swiftenvLocation)",
                commandSuggestion: "git clone https://github.com/kylef/swiftenv \(Config.swiftenvLocation)")
        }
        
        let swiftVersion: String
        let global: Bool
        
        if let fileVersion = try? String(contentsOfFile: ".swift-version", encoding: .utf8) {
            let trimmedFileVersion = fileVersion.trimmingCharacters(in: .whitespacesAndNewlines)
            if let configVersion = Config.swiftVersion, configVersion != trimmedFileVersion {
                throw TaskError(message: "Conflicting Swift versions - Config.swiftVersion = \(configVersion), `.swift-version` = \(trimmedFileVersion)")
            }
            swiftVersion = trimmedFileVersion
            global = false
        } else if let configVersion = Config.swiftVersion {
            swiftVersion = configVersion
            global = true
        } else {
            throw TaskError(message: "You must specify which Swift version to use either in your configuration file (Config.swiftVersion) or in a `.swift-version` file.")
        }
        
        let existingSwifts = try server.capture("\(swiftenvExecutable) versions")
        if !existingSwifts.contains(swiftVersion) {
            try server.execute("\(swiftenvExecutable) install \(swiftVersion)")
            try server.execute("\(swiftenvExecutable) rehash")
        }
        
        if global {
            try server.execute("\(swiftenvExecutable) global \(swiftVersion)")
        }
    }
    
}
*/
