//
//  Server.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation
import SwiftCLI
import Rainbow
import Spawn
import CNMSSH

public class Servers {
    
    static var servers: [Server] = []
    
    public static func add(ip: String, user: String, roles: [ServerRole], authMethod: SSHAuthMethod? = nil) {
        do {
            let server = try Server(ip: ip, user: user, roles: roles, authMethod: authMethod)
            servers.append(server)
        } catch {
            print("Couldn't connect to \(user)@\(ip)")
            exit(1)
        }
    }
    
    public static func add(SSHHost: String, roles: [ServerRole]) {
        do {
            let server = try Server(SSHHost: SSHHost, roles: roles)
            servers.append(server)
        } catch {
            print("Couldn't connect to \(SSHHost)")
            exit(1)
        }
    }
    
    public static func add(docker container: String, roles: [ServerRole]) {
        servers.append(Server(dockerContainer: container, roles: roles))
    }
    
}

public enum ServerRole {
    case app
    case db
    case web
}

public class Server {
    
    let roles: [ServerRole]
    let commandExecutor: ServerCommandExecutor
    var commandStack: [String] = []
    
    static func createDummyServer() -> Server {
        return Server(commandExecutor: DummyServer(), roles: [.app, .db, .web])
    }
    
    public convenience init(ip: String, user: String, roles: [ServerRole], authMethod: SSHAuthMethod?) throws {
        self.init(commandExecutor: try UserServer(ip: ip, user: user, authMethod: authMethod), roles: roles)
    }
    
    public convenience init(SSHHost: String, roles: [ServerRole]) throws {
        self.init(commandExecutor: try UserServer(SSHHost: SSHHost), roles: roles)
    }
    
    public convenience init(dockerContainer: String, roles: [ServerRole]) {
        self.init(commandExecutor: DockerServer(container: dockerContainer), roles: roles)
    }
    
    public init(commandExecutor: ServerCommandExecutor, roles: [ServerRole]) {
        self.roles = roles
        self.commandExecutor = commandExecutor
    }
    
    // MARK: - Public
    
    public func within(_ directory: String, block: () throws -> ()) rethrows {
        commandStack.append("cd \(directory)")
        try block()
        commandStack.removeLast()
    }
    
    public func fileExists(_ file: String) -> Bool {
        let call = "test -f \(file)"
        do {
            try execute(call)
        } catch {
            return false
        }
        return true
    }
    
    public func directoryExists(_ directory: String) -> Bool {
        let call = "test -d \(directory)"
        do {
            try execute(call)
        } catch {
            return false
        }
        return true
    }
    
    public func execute(_ command: String) throws {
        _ = try run(commands: [command], capture: false)
    }
    
    public func capture(_ command: String) throws -> String? {
        return try run(commands: [command], capture: true)
    }
    
    public func executeWithOutputMatchers(_ command: String, matchers: [OutputMatcher]) throws {
        _ = try run(commands: [command], capture: false, matchers: matchers)
    }
    
    // MARK: - Private
    
    private func run(commands: [String], capture: Bool, matchers: [OutputMatcher]? = nil) throws -> String? {
        let finalCommands = commandStack + commands
        let call = finalCommands.joined(separator: "; ")
        
        Logger.logCall(call, on: commandExecutor.id)
        
        return try commandExecutor.execute(call, capture: capture, matchers: matchers)
    }
    
}

extension Server: CustomStringConvertible {
    
    public var description: String {
        return commandExecutor.id
    }
    
}

// MARK: - ServerCommandExecutor

public protocol ServerCommandExecutor {
    var id: String { get }
    
    func execute(_ call: String, capture: Bool, matchers: [OutputMatcher]?) throws -> String?
}

// MARK: - UserServer

public enum SSHAuthMethod {
    case key(String)
    case password(String)
}

extension Config {
    public static var SSHAuthMethod: SSHAuthMethod? = nil
}

enum ServerError: Error {
    case SSHConnectionFailed
}

public class UserServer: ServerCommandExecutor {
    
    public let id: String
    let session: NMSSHSession
    
    public init(ip: String, user: String, authMethod: SSHAuthMethod?) throws {
        guard let session = NMSSHSession.connect(toHost: ip, withUsername: user) else {
            throw ServerError.SSHConnectionFailed
        }
        
        let auth: SSHAuthMethod
        if let authMethod = authMethod {
            auth = authMethod
        } else {
            guard let method = Config.SSHAuthMethod else {
                throw TaskError.error("You must either pass in a SSH auth method in your `Server.add` call or specify `Config.SSHAuthMethod` in your configuration file")
            }
            auth = method
        }
        
        switch auth {
        case let .key(key):
            if !session.connectToAgent() {
                let passphrase = Input.awaitInput(message: "Enter passphrase (empty for no passphrase):", secure: true)
                guard session.authenticate(byPublicKey: key + ".pub", privateKey: key, andPassword: passphrase) else {
                    throw ServerError.SSHConnectionFailed    
                }
            }
        case let .password(password):
            guard session.authenticate(byPassword: password) else {
                throw ServerError.SSHConnectionFailed
            }
        }
        
        session.channel.requestPty = true
        
        self.id = "\(user)@\(ip)"
        self.session = session
    }
    
    public init(SSHHost: String) throws {
        guard let file = NMSSHConfig(fromFile: ("~/.ssh/config" as NSString).expandingTildeInPath),
            let hostConfigs = file.hostConfigs as? [NMSSHHostConfig] else {
            throw ServerError.SSHConnectionFailed
        }
        
        var findSession: NMSSHSession?
        var identityFiles: [String] = []
        for hostConfig in hostConfigs {
            for pattern in (hostConfig.hostPatterns as? [String] ?? []) { 
                if pattern == SSHHost { // TODO: Support patterns
                    findSession = NMSSHSession.connect(toHost: hostConfig.hostname, withUsername: hostConfig.user)
                    identityFiles = (hostConfig.identityFiles as? [String]) ?? []
                    break
                }
            }
        }
        
        guard let session = findSession else {
            throw ServerError.SSHConnectionFailed
        }
        
        if !session.connectToAgent() {
            let passphrase = Input.awaitInput(message: "Enter passphrase (empty for no passphrase):", secure: true)
            
            var success = false
            for file in identityFiles {
                if session.authenticate(byPublicKey: file + ".pub", privateKey: file, andPassword: passphrase) {
                    success = true
                    break
                }
            }
            
            guard success else {
                throw ServerError.SSHConnectionFailed    
            }
        }
        
        self.id = SSHHost
        self.session = session
    }
    
    public func execute(_ call: String, capture: Bool, matchers: [OutputMatcher]?) throws -> String? {
        let output = session.channel.executeSwift(call)!
        let message = output[0] as! String
        matchers?.forEach { $0.match(message) }
        if output[1] is NSError {
            print(message)
            throw TaskError.commandFailed
        } else {
            if capture {
                return message
            } else {
                print(message)
                return nil
            }
        }
    }
    
}

// MARK: - DockerServer

public class DockerServer: ServerCommandExecutor {
    
    public let id: String
    
    public init(container: String) {
        self.id = container
    }
    
    public func execute(_ call: String, capture: Bool, matchers: [OutputMatcher]?) throws -> String? {
        let tmpFile = "/tmp/docker_call"
        try call.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        
        let copyTask = Process()
        copyTask.launchPath = "/usr/local/bin/docker"
        copyTask.arguments = ["cp", tmpFile, "\(id):\(tmpFile)"]
        copyTask.launch()
        copyTask.waitUntilExit()
        
        var captured = ""
        let spawned = try Spawn(args: ["/usr/local/bin/docker", "exec", id, "bash", tmpFile], output: { (output) in
            if capture {
                captured += output
            } else {
                print(output, terminator: "")
            }
            fflush(stdout)
            matchers?.forEach { $0.match(output) }
        })
        
        guard spawned.waitForExit() == 0 else {
            throw TaskError.commandFailed
        }
        
        return captured.isEmpty ? nil : captured
    }
    
}

public class DummyServer: ServerCommandExecutor {
    
    public let id = "DummyServer"
    
    public func execute(_ call: String, capture: Bool, matchers: [OutputMatcher]?) throws -> String? {
        return nil
    }
    
}

// MARK: - OutputMatcher

public struct OutputMatcher {
    
    let regex: NSRegularExpression?
    let onMatch: (_ text: String) -> ()
    
    init(regex: String, onMatch: @escaping (_ text: String) -> ()) {
        self.regex = try? NSRegularExpression(pattern: regex, options: [])
        self.onMatch = onMatch
    }
    
    func match(_ output: String) {
        guard let regex = regex else {
            return
        }
        if regex.numberOfMatches(in: output, options: [], range: NSRange(location: 0, length: output.characters.count)) > 0 {
            onMatch(output)
        }
    }
    
}
