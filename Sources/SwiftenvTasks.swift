//
//  SwiftenvTasks.swift
//  Flock
//
//  Created by Jake Heiser on 4/27/17.
//
//

public extension TaskSource {
    static let swiftenv = TaskSource(tasks: [
        SwiftenvInstallationTask(),
        SwiftTask()
    ])
}

public extension Config {
    static var swiftVersion: String? = nil
}

private let swiftenv = "swiftenv"
private let location = "$HOME/.swiftenv"

class SwiftenvInstallationTask: Task {
    let name = "install-swiftenv"
    let namespace = swiftenv
    
    func run(on server: Server) throws {
        try server.execute("git clone https://github.com/kylef/swiftenv.git \(location)")
        
        let bashrc = "~/.bashrc"
        
        let swiftenvLoad = [
            "export SWIFTENV_ROOT=\"\(location)\"",
            "export PATH=\"\\$SWIFTENV_ROOT/bin:\\$PATH\"",
            "eval \"\\$(swiftenv init -)\""
            ].joined(separator: "; ")
        
        try server.execute("sed -i '1i \(swiftenvLoad)' \(bashrc)")
    }
}

class SwiftTask: Task {
    
    let name = "swift"
    let namespace = swiftenv
    let hookTimes: [HookTime] = [.before("deploy:build")]
    
    func run(on server: Server) throws {
        if !server.directoryExists(location) {
            try invoke("swiftenv:install-swiftenv")
        }
        
        let swiftVersion: String
        let global: Bool
        
        if let fileVersion = try? String(contentsOfFile: ".swift-version", encoding: .utf8) {
            let trimmedFileVersion = fileVersion.trimmingCharacters(in: .whitespacesAndNewlines)
            if let configVersion = Config.swiftVersion, configVersion != trimmedFileVersion {
                throw TaskError.error("Conflicting Swift versions - Config.swiftVersion = \(configVersion), `.swift-version` = \(trimmedFileVersion)")
            }
            swiftVersion = trimmedFileVersion
            global = false
        } else if let configVersion = Config.swiftVersion {
            swiftVersion = configVersion
            global = true
        } else {
            throw TaskError.error("You must specify which Swift version to use either in your configuration file (Config.swiftVersion) or in a `.swift-version` file.")
        }
        
        if let existingSwifts = try server.capture("swiftenv versions"), !existingSwifts.contains(swiftVersion) {
            try server.execute("swiftenv install \(swiftVersion)")
        }
        
        if global {
            try server.execute("swiftenv global \(swiftVersion)")
        }
    }
    
}
