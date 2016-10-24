//
//  DeployCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

extension Flock {
    public static let Tools = ToolsCluster()
}

extension Config {
    public static var swiftVersion: String? = nil
}

public class ToolsCluster: ExecutableCluster {
    public let name = "tools"
    public let tasks: [Task] = [
        DependencyInstallationTask(),
        SwiftInstallationTask()
    ]
}

class DependencyInstallationTask: Task {
    let name = "dependencies"
    
    func run(on server: Server) throws {
        print("Installing Swift dependencies")
        try server.execute("sudo apt-get -qq install clang libicu-dev git libpython2.7 libcurl4-openssl-dev")
    }
}

class SwiftInstallationTask: Task {
    let name = "swift"
    
    private let swiftEnv = "~/.swiftenv"
    
    func run(on server: Server) throws {
        if server.directoryExists(swiftEnv) {
            print("swiftenv alrady installed")
        } else {
            try installSwiftenv(on: server)
        }
        
        guard let swiftVersion = Config.swiftVersion else {
            throw TaskError.error("You must specify in your configuration file which Swift version to install.")
        }
        
        if let existingSwifts = try server.capture("swiftenv versions"), existingSwifts.contains(swiftVersion) {
            try server.execute("swiftenv global \(swiftVersion)")
        } else {
            print("Installing Swift")
            try server.execute("swiftenv install \(swiftVersion)")
        }
    }
    
    func installSwiftenv(on server: Server) throws {
        print("Installing swiftenv")
        try server.execute("git clone https://github.com/kylef/swiftenv.git \(swiftEnv)")
        
        let tmpFile = "/tmp/bashrc"
        let bashrc = "~/.bashrc"
        
        let bashRC = [
            "export SWIFTENV_ROOT=\"$HOME/.swiftenv\"",
            "export PATH=\"$SWIFTENV_ROOT/bin:$PATH\"",
            "eval \"$(swiftenv init -)\""
        ].joined(separator: "; ")
        try server.execute("echo -e '\(bashRC)' > \(tmpFile)")
        try server.execute("echo >> \(tmpFile)")
        try server.execute("cat \(bashrc) >> \(tmpFile)")
        try server.execute("cat \(tmpFile) > \(bashrc)")
    }
}
