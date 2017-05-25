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
import SSH

public class Servers {
    
    static var servers: [Server] = []
    
    public static func add(ip: String, user: String, roles: [ServerRole], authMethod: SSH.AuthMethod? = nil) {
        do {
            let server = try Server(ip: ip, user: user, roles: roles, authMethod: authMethod)
            servers.append(server)
        } catch {
            print("Couldn't connect to \(user)@\(ip)")
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
    
    public convenience init(ip: String, user: String, roles: [ServerRole], authMethod: SSH.AuthMethod?) throws {
        self.init(commandExecutor: try UserServer(ip: ip, user: user, authMethod: authMethod), roles: roles)
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

extension Config {
    public static var SSHAuthMethod: SSH.AuthMethod? = nil
}

enum ServerError: Error {
    case SSHConnectionFailed
}

public class UserServer: ServerCommandExecutor {
    
    public let id: String
    let session: SSH.Session
    
    public init(ip: String, user: String, authMethod: SSH.AuthMethod?) throws {
        guard let session = try? SSH.Session(host: ip) else {
            throw ServerError.SSHConnectionFailed
        }
        
        let auth: SSH.AuthMethod
        if let authMethod = authMethod {
            auth = authMethod
        } else {
            guard let method = Config.SSHAuthMethod else {
                throw TaskError.error("You must either pass in a SSH auth method in your `Server.add` call or specify `Config.SSHAuthMethod` in your configuration file")
            }
            auth = method
        }

        do {
            try session.authenticate(username: user, authMethod: auth)
        } catch {
            throw ServerError.SSHConnectionFailed
        }
        
        // session.channel.requestPty = true
        
        self.id = "\(user)@\(ip)"
        self.session = session
    }
    
    public func execute(_ call: String, capture: Bool, matchers: [OutputMatcher]?) throws -> String? {
        if capture {
            let (status, output) = try session.capture(call)
            guard status == 0 else {
                print(output)
                throw TaskError.commandFailed
            }
            return output
        } else {
            guard try session.execute(call) == 0 else {
                throw TaskError.commandFailed
            }
            return nil
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
