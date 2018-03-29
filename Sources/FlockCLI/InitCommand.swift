//
//  InitCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import Rainbow
import SwiftCLI

class InitCommand: FlockCommand {
  
    let name = "init"
    let shortDescription = "Initializes Flock in the current directory"
    
    func execute() throws {
        guard !flockIsInitialized else {
            throw CLI.Error(message: "Error: ".red + "Flock has already been initialized")
        }
        
        print("Creating Flock.swift")
        
        try defaultFlockfile.write(toFile: flockPath, atomically: true, encoding: .utf8)
        
        print("Building dependencies")
        do {
            try Beak.execute(args: ["run", "--path", "Flock.swift"])
        } catch {
            print("Dependency build failed".red)
            return
        }
        
        print("Successfully initialized Flock".green)
    }
    
}

let defaultFlockfile = """
// beak: jakeheis/Flock FlockLib @ .branch("beak")

import FlockLib
import Foundation
import Shout

// MARK: - Environments

let myProject = Project(
    name: "MyProject",
    repoURL: "https://github.com/me/Project"
)

public let production = Environment(
    project: myProject,
    servers: [
        ServerLogin(ip: "1.1.1.1", user: "deploy", auth: SSHKey(privateKey: "aKey"))
    ]
)

// MARK: - Tasks

public func deploy(env: Environment = production) {
    Flock.run(in: env) { (server) in
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMddHHMMSS"
        let timestamp = formatter.string(from: Date())

        let cloneDirectory = "\\(env.releasesDirectory)/\\(timestamp)"
        try server.execute("git clone --depth 1 \\(env.project.repoURL) \\(cloneDirectory)")

        try server.execute("swift build -C \\(cloneDirectory) -c release")

        try server.execute("ln -sfn \\(cloneDirectory) \\(env.currentDirectory)")
    }
}

"""
