//
//  DeployCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation

extension Flock {
    public static let Deploy = DeployCluster()
}

extension Config {
    public static var projectName: String? = nil // Must be supplied
    public static var deployDirectory = "/var/www"
    
    public static var repoURL: String? = nil // Must be supplied
    
    public static var projectDirectory: String {
        let project = projectName ?? "Project"
        return "\(deployDirectory)/\(project)"
    }
    
    public static var currentDirectory: String {
        return "\(projectDirectory)/current"
    }
    
    public static var releasesDirectory: String {
        return "\(projectDirectory)/releases"
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
        
        let currentTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYYMMddHHMMSS"
        let timestamp = formatter.stringFromDate(currentTime)
        
        let cloneDirectory = "\(Config.releasesDirectory)/\(timestamp)"
        try server.execute("git clone \(repoURL) \(cloneDirectory)")
        try server.execute("ln -s \(cloneDirectory) \(Config.currentDirectory)")
    }
}

class BuildTask: Task {
    let name = "build"
    
    func run(server: ServerType) throws { 
        print("Building swift project")
        try server.within(Config.currentDirectory) {
            try server.execute("swift build")
        }
    }
}
