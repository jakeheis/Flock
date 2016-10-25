//
//  DeployCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation

extension Flock {
    public static let Deploy: [Task] = [
        DeployTask(),
        GitTask(),
        BuildTask(),
        LinkTask()
    ]
}

extension Config {
    public static var projectName = "Project" // Must be supplied
    public static var executableName = "Project" // Must be supplied
    public static var deployDirectory = "/var/www"
    public static var repoURL: String? = nil // Must be supplied
}

private let deploy = "deploy"

class DeployTask: Task {
    let name = deploy
    
    func run(on server: Server) throws {
        try invoke("deploy:git")
        try invoke("deploy:build")
        try invoke("deploy:link")
    }
}

class GitTask: Task {
    let name = "git"
    let namespace = deploy
    
    func run(on server: Server) throws {
        guard let repoURL = Config.repoURL else {
            throw TaskError.error("You must supply a repoURL in your configuration")
        }
        
        let currentTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMddHHMMSS"
        let timestamp = formatter.string(from: currentTime)
        
        let cloneDirectory = "\(Paths.releasesDirectory)/\(timestamp)"
        try server.execute("git clone \(repoURL) \(cloneDirectory)")
        try server.execute("ln -sfn \(cloneDirectory) \(Paths.nextDirectory)")
    }
}

class BuildTask: Task {
    let name = "build"
    let namespace = deploy
    
    func run(on server: Server) throws {
        print("Building swift project")
        
        let buildPath: String
        if server.directoryExists(Paths.nextDirectory) {
            buildPath = Paths.nextDirectory
        } else {
            buildPath = Paths.currentDirectory
        }
        try server.within(buildPath) {
            try server.execute("swift build")
        }
    }
}

class LinkTask: Task {
    let name = "link"
    let namespace = deploy
    
    func run(on server: Server) throws {
        guard let nextDestination = try server.capture("readlink \(Paths.nextDirectory)") else {
            throw TaskError.error("Couldn't find location of next directory to link - try running full `flock deploy`")
        }
        try server.execute("ln -sfn \(nextDestination) \(Paths.currentDirectory)")
        try server.execute("rm \(Paths.nextDirectory)")
    }
}
