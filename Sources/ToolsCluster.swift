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

public class ToolsCluster: Cluster {
    public let name = "tools"
    public let tasks: [Task] = [
        DependencyInstallationTask(),
        SwiftInstallationTask()
    ]
}

class DependencyInstallationTask: Task {
    let name = "dependencies"
    
    func run(server: ServerType) throws {
        print("Installing Swift dependencies")
        try server.execute("sudo apt-get -y install clang libicu-dev git")
    }
}

class SwiftInstallationTask: Task {
    let name = "swift"
    
    func run(server: ServerType) throws {
        print("Installing swiftenv")
        try server.execute("git clone https://github.com/kylef/swiftenv.git ~/.swiftenv")
        
        let tmpFile = "/tmp/bashrc"
        let bashrc = "~/.bashrc"
        
        let bashRC = [
            "export SWIFTENV_ROOT=\"$HOME/.swiftenv\"",
            "export PATH=\"$SWIFTENV_ROOT/bin:$PATH\"",
            "eval \"$(swiftenv init -)\""
        ].joinWithSeparator("; ")
        try server.execute("echo -e '\(bashRC)' > \(tmpFile)")
        try server.execute("echo >> \(tmpFile)")
        try server.execute("cat \(bashrc) >> \(tmpFile)")
        try server.execute("cat \(tmpFile) > \(bashrc)")
        
        print("Installing Swift")
        guard let swiftVersion = Config.swiftVersion else {
            print("ERROR: You must specify in your configuration file which Swift version to install.")
            return
        }
        try server.execute("swiftenv install \(swiftVersion)")
    }
}
