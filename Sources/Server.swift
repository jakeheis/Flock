//
//  Server.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation
import Rainbow
import Spawn
import SSH

public class Servers {
    
    static var servers: [Server] = []
    
    public static func add(ip: String, user: String, roles: [ServerRole], authMethod: SSH.AuthMethod? = nil) {
        do {
            let server = try SSHServer(ip: ip, user: user, roles: roles, authMethod: authMethod)
            servers.append(server)
        } catch let error {
            print("Couldn't connect to \(user)@\(ip) (error: \(error))")
            exit(1)
        }
    }
    
    public static func add(docker container: String, roles: [ServerRole]) {
        servers.append(DockerServer(container: container, roles: roles))
    }
    
}

public enum ServerRole {
    case app
    case db
    case web
}

public protocol Server: class, CustomStringConvertible {
    var id: String { get }
    var roles: [ServerRole] { get }
    var commandStack: [String] { get set }
    
    func _internalExecute(_ command: String) throws
    func _internalCapture(_ command: String) throws -> String
    func _internalExecuteWithSuggestions(_ command: String, suggestions: [ErrorSuggestion]) throws
}

extension Server {
    
    public var description: String {
        return id
    }
    
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
    
    public func executeWithSuggestions(_ command: String, suggestions: [ErrorSuggestion]) throws {
        try _internalExecuteWithSuggestions(prepCommand(command), suggestions: suggestions)
    }
    
    public func execute(_ command: String) throws {
        try _internalExecute(prepCommand(command))
    }
    
    public func capture(_ command: String) throws -> String {
        return try _internalCapture(prepCommand(command))
    }
    
    private func prepCommand(_ command: String) -> String {
        let finalCommands = commandStack + [command]
        let call = finalCommands.joined(separator: "; ")
        Logger.logCall(call, on: id)
        return call
    }
    
}

// MARK: - UserServer

public extension Config {
    static var SSHAuthMethod: SSH.AuthMethod? = nil
}

public class SSHServer: Server {
    
    public let id: String
    public let roles: [ServerRole]
    public var commandStack: [String] = []
    
    let session: SSH.Session
    
    public init(ip: String, user: String, roles: [ServerRole], authMethod: SSH.AuthMethod?) throws {
        let session = try SSH.Session(host: ip)
        session.ptyType = .vanilla
        
        let auth: SSH.AuthMethod
        if let authMethod = authMethod {
            auth = authMethod
        } else {
            guard let method = Config.SSHAuthMethod else {
                throw TaskError(message: "You must either pass in a SSH auth method in your `Server.add` call or specify `Config.SSHAuthMethod` in your configuration file")
            }
            auth = method
        }
        
        try session.authenticate(username: user, authMethod: auth)
        
        self.id = "\(user)@\(ip)"
        self.roles = roles
        self.session = session
    }
    
    public func _internalExecute(_ command: String) throws {
        let status = try session.execute(command)
        guard status == 0 else {
            throw TaskError(status: status)
        }
    }
    
    public func _internalCapture(_ command: String) throws -> String {
        let (status, output) = try session.capture(command)
        guard status == 0 else {
            print(output)
            throw TaskError(status: status)
        }
        return output
    }
    
    public func _internalExecuteWithSuggestions(_ command: String, suggestions: [ErrorSuggestion]) throws {
        var captured = ""
        let status = try session.execute(command, output: { (output) in
            print(output, terminator: "")
            fflush(stdout)
            captured += output
        })
        guard status == 0 else {
            let suggestion = suggestions.first(where: { $0.matches(captured) })
            throw TaskError(status: status, commandSuggestion: suggestion?.command)
        }
    }
    
}

// MARK: - DockerServer

public class DockerServer: Server {
    
    public let id: String
    public let roles: [ServerRole]
    public var commandStack: [String] = []
    
    public init(container: String, roles: [ServerRole]) {
        self.id = container
        self.roles = roles
    }
    
    public func _internalExecute(_ command: String) throws {
        try makeCall(command) { (output) in
            print(output, terminator: "")
            fflush(stdout)
        }
    }
    
    public func _internalCapture(_ command: String) throws -> String {
        var captured = ""
        try makeCall(command) { (output) in
            captured += output
        }
        return captured
    }
    
    public func _internalExecuteWithSuggestions(_ command: String, suggestions: [ErrorSuggestion]) throws {
        var captured = ""
        do {
            try makeCall(command) { (output) in
                print(output, terminator: "")
                fflush(stdout)
                captured += output
            }
        } catch var error as TaskError {
            error.commandSuggestion = suggestions.first(where: { $0.matches(captured) })?.command
            throw error
        }
    }
    
    private func makeCall(_ call: String, output: @escaping OutputClosure) throws {
        let tmpFile = "/tmp/docker_call"
        try call.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        
        let copyTask = Process()
        copyTask.launchPath = "/usr/local/bin/docker"
        copyTask.arguments = ["cp", tmpFile, "\(id):\(tmpFile)"]
        copyTask.launch()
        copyTask.waitUntilExit()
        
        let spawned = try Spawn(args: ["/usr/local/bin/docker", "exec", id, "bash", tmpFile], output: output)
        
        let status = spawned.waitForExit()
        guard status == 0 else {
            throw TaskError(status: status)
        }
    }
    
}

public class DummyServer: Server {
    
    public let id = "DummyServer"
    public let roles: [ServerRole] = []
    public var commandStack: [String] = []
    
    public func _internalExecute(_ command: String) throws {}
    public func _internalCapture(_ command: String) throws -> String { return "" }
    public func _internalExecuteWithSuggestions(_ command: String, suggestions: [ErrorSuggestion]) throws {}
}

// MARK: - OutputMatcher

public struct ErrorSuggestion {
    
    let error: String
    let command: String
    
    func matches(_ output: String) -> Bool {
        return output.contains(error)
    }
    
}
