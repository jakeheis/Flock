//
//  ToolsCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

extension Flock {
    public static let Tools: [Task] = [
        ToolsTask(),
        DependencyInstallationTask(),
        SwiftInstallationTask()
    ]
}

extension Config {
    public static var swiftVersion: String? = nil
}

private let tools = "tools"

class ToolsTask: Task {
    let name = tools
    
    func run(on server: Server) throws {
        try invoke("tools:dependencies")
        try invoke("tools:swift")
    }
}

class DependencyInstallationTask: Task {
    let name = "dependencies"
    let namespace = tools
    
    func run(on server: Server) throws {
        try server.execute("sudo apt-get -qq update")
        try server.execute("sudo apt-get -qq install clang libicu-dev git libpython2.7 libcurl4-openssl-dev")
    }
}

class SwiftInstallationTask: Task {
    let name = "swift"
    let namespace = tools
    
    private let swiftEnv = "/usr/local/swiftenv"
    
    func run(on server: Server) throws {
        if !server.directoryExists(swiftEnv) {
            try installSwiftenv(on: server)
        }
        
        guard let swiftVersion = Config.swiftVersion else {
            throw TaskError.error("You must specify in your configuration file which Swift version to install.")
        }
        
        if let existingSwifts = try server.capture("swiftenv versions"), existingSwifts.contains(swiftVersion) {
            try server.execute("sudo swiftenv global \(swiftVersion)")
        } else {
            try server.execute("sudo swiftenv install \(swiftVersion)")
            try server.execute("sudo chmod -R +r \(swiftEnv)")
        }
    }
    
    func installSwiftenv(on server: Server) throws {
        try server.execute("sudo git clone https://github.com/kylef/swiftenv.git \(swiftEnv)")
        
        let bashrc = "/etc/bash.bashrc"
        
        let swiftenvLoad = [
            "export SWIFTENV_ROOT=\"\(swiftEnv)\"",
            "export PATH=\"\\$SWIFTENV_ROOT/bin:\\$PATH\"",
            "eval \"\\$(swiftenv init -)\""
        ].joined(separator: "; ")
        
        try server.execute("sudo sed -i '1i \(swiftenvLoad)' \(bashrc)")
    }
}
