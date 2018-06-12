//
//  InitCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import Foundation
import PathKit
import Rainbow
import SwiftCLI

class InitCommand: FlockCommand {
  
    let name = "init"
    let shortDescription = "Initializes Flock in the current directory"
    
    func execute() throws {
        guard !flockIsInitialized else {
            throw FlockError(message: "Flock has already been initialized")
        }
        
        stdout <<< ""
        stdout <<< "1. Generating " + "Flock.swift".blue
        stdout <<< ""
        
        let contents = generateContents()
        try Beak.flockPath.write(contents)
        
        stdout <<< ""
        stdout <<< "2. Building dependencies (this may take a minute)"
        
        try Beak.run()
        
        stdout <<< ""
        stdout <<< "Success!".green.bold + " Flock has been initialized"
        stdout <<< ""
        stdout <<< "Next steps:".bold
        stdout <<< " 1. Open Flock.swift and finish filling out the environment info"
        stdout <<< " 2. Read through the rest of the Flock.swift file and follow the directions throughout that file"
        stdout <<< " 3. Run `flock deploy`"
        stdout <<< ""
    }
    
    private func generateContents() -> String {
        let defaultName = Path(".").absolute().lastComponent
        let inputName = Input.readLine(prompt: "Project name: (\(defaultName))")
        
        let defaultUrl = try? capture("git", "remote", "get-url", "origin").stdout
        let prompt = "Repository url: " + (defaultUrl.flatMap(({ "(\($0)) " })) ?? "")
        let inputUrl = Input.readLine(prompt: prompt)
        
        return generateFlockfile(
            name: inputName.isEmpty ? defaultName : inputName,
            url: inputUrl.isEmpty ? (defaultUrl ?? "") : inputUrl
        )
    }
    
}

private func generateFlockfile(name: String, url: String) -> String {
    return """
// beak: jakeheis/Flock @ .branch("beak")

import Flock
import Foundation
import Shout

// MARK: - Environments

let project = Project(
    name: "\(name)",
    repoURL: "\(url)"
)

public let production = Environment(
    project: project,
    name: "production",
    servers: [
        // ServerLogin(ip: "1.1.1.1", user: "deploy", auth: SSHKey(privateKey: "aKey")),
        // ServerLogin(ip: "1.1.1.2", user: "deploy", auth: SSHPassword(password: "aPassword")),
        // ServerLogin(ip: "1.1.1.3", port: 234, user: "deploy", auth: SSHAgent())
    ]
)

//
// Uncomment if you have a staging environment:
//
/*
public let staging = Environment(
    project: project,
    name: "staging",
    servers: [
        ServerLogin(ip: "1.1.1.1", user: "deploy", auth: SSHKey(privateKey: "aKey"))
    ]
)
*/

// MARK: - Tasks

/// Deploy the project
public func deploy(env: Environment = production) {
    Flock.run(in: env) { (server) in
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMddHHMMSS"
        let timestamp = formatter.string(from: Date())
        
        let cloneDirectory = "\\(env.releasesDirectory)/\\(timestamp)"
        try server.execute("git clone --depth 1 \\(env.project.repoURL) \\(cloneDirectory)")
        
        // Uncomment if using swiftenv:
        // try swiftenv(on: server, env: env, directory: cloneDirectory)
        
        try server.execute("swift build -C \\(cloneDirectory) -c release")
        
        try server.execute("ln -sfn \\(cloneDirectory) \\(env.currentDirectory)")
    
        // Uncomment after completing the restartServer function below
        // try restartServer(on: server, env: env)
    }
}

/// Start the server
public func startServer(env: Environment = production) {
    Flock.run(in: env) { (server) in
        try startServer(on: server, env: env)
    }
}

/// Print the status of the server
public func status(env: Environment = production) {
    Flock.run(in: env) { (server) in
        try status(on: server, env: env)
    }
}

/// Stop the server
public func stopServer(env: Environment = production) {
    Flock.run(in: env) { (server) in
        try stopServer(on: server, env: env)
    }
}

/// Restart the server
public func restartServer(env: Environment = production) {
    Flock.run(in: env) { (server) in
        try restartServer(on: server, env: env)
    }
}

//
// You can add your own tasks here
//
/*
public func myTask(env: Environment = production) {
    Flock.run(in: env) { (server) in
        // Do anything!
    }
}
*/

// MARK: -

func startServer(on server: Server, env: Environment) throws {
    //
    // Uncomment the following if you *are* using supervisord:
    //
    /*
    try executeSupervisor(command: "start", server: server, env: env)
    */
    
    //
    // Uncomment the following if you *are not* using supervisord:
    //
    /*
    try server.withPty(nil) {
        var command = "swift run -c release"
     
        //
        // Some frameworks encourage additional arguments to be passed
        // Check their documention for details; the following are examples:
        //
        // Vapor:
        // command += " --env \\(env.name) --workDir=\\(env.currentDirectory)"
        // Kitura:
        // command += " --env=\\(env.name)"
        // Perfect (example; many options available):
        // command += " --port customPort --root customRoot"

        try server.within(env.currentDirectory) {
            try server.execute("nohup \\(command) > /dev/null 2>&1 &")
        }
    }
    */
}

func status(on server: Server, env: Environment) throws {
    //
    // Uncomment the following if you *are* using supervisord:
    //
    /*
     try executeSupervisor(command: "status", server: server, env: env)
     */
    
    //
    // Uncomment the following if you *are not* using supervisord:
    //
    /*
    if let pid = try findServerPid(on: server) {
        print("Server running as process \\(pid)")
    } else {
        print("Server not running")
    }
    */
}

func stopServer(on server: Server, env: Environment) throws {
    //
    // Uncomment the following if you *are* using supervisord:
    //
    /*
    try executeSupervisor(command: "stop", server: server, env: env)
    */
    
    //
    // Uncomment the following if you *are not* using supervisord:
    //
    /*
    if let pid = try findServerPid(on: server) {
        try server.execute("kill -9 \\(pid)")
    } else {
        print("Server not running")
    }
    */
}

func restartServer(on server: Server, env: Environment) throws {
    //
    // Uncomment the following if you *are* using supervisord:
    //
    /*
     try executeSupervisor(command: "restart", server: server, env: env)
     */
    
    //
    // Uncomment the following if you *are not* using supervisord:
    //
    /*
     try stopServer(on: server, env: env)
     try startServer(on: server, env: env)
     */
}

func swiftenv(on server: Server, env: Environment, directory: String) throws {
    guard server.commandExists("swiftenv") else {
        throw TaskError(message: "swiftenv not found; ensure it is installed and executable")
    }
    
    guard let fileVersion = try? server.capture("cat \\(directory)/.swift-version") else {
        throw TaskError(message: "You must specify which Swift version to use in a `.swift-version` file.")
    }

    let swiftVersion = fileVersion.trimmingCharacters(in: .whitespacesAndNewlines)

    let existingSwifts = try server.capture("swiftenv versions")
    if !existingSwifts.contains(swiftVersion) {
        try server.execute("swiftenv install \\(swiftVersion)")
        try server.execute("swiftenv rehash")
    }
}

func executeSupervisor(command: String, server: Server, env: Environment) throws {
    try server.execute("supervisorctl \\(command) \\(env.project.name):*")
}

func findServerPid(on server: Server) throws -> String? {
    let processes = try server.capture("ps aux | grep \\"\\\\.build/.*/release\\"")
    
    let lines = processes.components(separatedBy: "\\n")
    for line in lines where !line.contains("grep") {
        let segments = line.components(separatedBy: " ").filter { !$0.isEmpty }
        if segments.count > 1 {
            return segments[1]
        }
        return segments.count > 1 ? segments[1] : nil
    }
    return nil
}

"""
}
