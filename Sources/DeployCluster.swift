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
    public static var projectName = "Project" // Must be supplied
    public static var deployDirectory = "/var/www"
    public static var repoURL: String? = nil // Must be supplied
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
        guard let repoURL = Config.repoURL else {
            throw TaskError.Error("You must supply a repoURL in your configuration")
        }
        
        let currentTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYYMMddHHMMSS"
        let timestamp = formatter.stringFromDate(currentTime)
        
        let cloneDirectory = "\(Paths.releasesDirectory)/\(timestamp)"
        try server.execute("git clone \(repoURL) \(cloneDirectory)")
        try server.execute("ln -sfn \(cloneDirectory) \(Paths.currentDirectory)")
    }
}

class BuildTask: Task {
    let name = "build"
    
    func run(server: ServerType) throws { 
        print("Building swift project")
        try server.within(Paths.currentDirectory) {
            try server.execute("swift build")
        }
    }
}
