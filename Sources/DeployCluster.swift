//
//  DeployCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

extension Flock {
    public static let Deploy = DeployCluster()
}

extension Config {
    public static var deployDirectory = "/var/www"
    public static var repoURL: String? = nil
    public static var projectName: String? = nil
    
    public static var projectDirectory: String {
        return "\(deployDirectory)/\(projectName)"
    }
}

public class DeployCluster: Cluster {
    public let name = "deploy"
    public let tasks: [Task] = [
        GitTask(),
        BuildTask()
    ]
}

class GitTask: Task {
    let name = "git"
    
    func run(server: ServerType) throws {
        print("Cloning project in \(Config.deployDirectory)")
        
        guard let repoURL = Config.repoURL, let projectName = Config.projectName else {
            throw TaskError.Error("You must supply a repoURL and a projectName in your configuration")
        }
        
        try server.execute("mkdir -p \(Config.deployDirectory)")
        try server.within(Config.deployDirectory) {
            try server.execute("git clone \(repoURL) \(projectName)")
        }
    }
}

class BuildTask: Task {
    let name = "build"
    
    func run(server: ServerType) throws { 
        print("Building swift project")
        try server.within(Config.projectDirectory) {
            try server.execute("swift build")
        }
    }
}
