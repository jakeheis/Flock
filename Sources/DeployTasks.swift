//
//  DeployTasks.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation

public extension TaskSource {
    static let deploy = TaskSource(tasks: [
        DeployTask(),
        GitTask(),
        BuildTask(),
        LinkTask()
    ])
}

public extension Config {
    static var projectName = "" // Must be supplied
    static var executableName = "" // Must be supplied
    static var repoURL = "" // Must be supplied
    static var deployDirectory = "/var/www"
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
        guard !Config.projectName.isEmpty else {
            throw TaskError(message: "You must supply a projectName in your configuration")
        }
        guard !Config.repoURL.isEmpty else {
            throw TaskError(message: "You must supply a repoURL in your configuration")
        }
        
        let currentTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMddHHMMSS"
        let timestamp = formatter.string(from: currentTime)
        
        let cloneDirectory = "\(Paths.releasesDirectory)/\(timestamp)"
        try server.execute("git clone \(Config.repoURL) \(cloneDirectory)")
        try server.execute("ln -sfn \(cloneDirectory) \(Paths.nextDirectory)")
    }
}

class BuildTask: Task {
    let name = "build"
    let namespace = deploy
    
    func run(on server: Server) throws {
        let buildPath: String
        if server.directoryExists(Paths.nextDirectory) {
            buildPath = Paths.nextDirectory
        } else {
            buildPath = Paths.currentDirectory
        }
        
        let suggestion = ErrorSuggestion(error: "error while loading shared libraries",
                                         command: "sudo apt-get update && sudo apt-get -y install clang libicu-dev libpython2.7 libcurl4-openssl-dev")
        
        let suggestions = [suggestion] + Config.serverFramework.buildErrorSuggestions
        
        let pathPrefix = TaskSource.swiftenv.beingUsed ? "PATH=\"\(Config.swiftenvLocation)/shims:${PATH}\" " : ""
        try server.executeWithSuggestions("\(pathPrefix)swift build -C \(buildPath) -c release", suggestions: suggestions)
    }
}

class LinkTask: Task {
    let name = "link"
    let namespace = deploy
    
    func run(on server: Server) throws {
        guard let nextDestination = try? server.capture("readlink \(Paths.nextDirectory)").trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw TaskError(message: "Couldn't find location of next directory to link",
                            commandSuggestion: "flock deploy (not just flock deploy:link)")
        }
        try server.execute("ln -sfn \(nextDestination) \(Paths.currentDirectory)")
        try server.execute("rm \(Paths.nextDirectory)")
    }
}
