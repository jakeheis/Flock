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
    func _internalExecuteWithOutputMatchers(_ command: String, matchers: [OutputMatcher]) throws
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
    
    public func executeWithOutputMatchers(_ command: String, matchers: [OutputMatcher]) throws {
        try _internalExecuteWithOutputMatchers(prepCommand(command), matchers: matchers)
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
                throw TaskError.error("You must either pass in a SSH auth method in your `Server.add` call or specify `Config.SSHAuthMethod` in your configuration file")
            }
            auth = method
        }
        
        try session.authenticate(username: user, authMethod: auth)
        
        self.id = "\(user)@\(ip)"
        self.roles = roles
        self.session = session
    }
    
    public func _internalExecute(_ command: String) throws {
        guard try session.execute(command) == 0 else {
            throw TaskError.commandFailed
        }
    }
    
    public func _internalCapture(_ command: String) throws -> String {
        let (status, output) = try session.capture(command)
        guard status == 0 else {
            print(output)
            throw TaskError.commandFailed
        }
        return output
    }
    
    public func _internalExecuteWithOutputMatchers(_ command: String, matchers: [OutputMatcher]) throws {
        let (status, output) = try session.capture(command)
        print(output)
        matchers.forEach { $0.match(output) }
        guard status == 0 else {
            throw TaskError.commandFailed
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
    
    public func _internalExecuteWithOutputMatchers(_ command: String, matchers: [OutputMatcher]) throws {
        try makeCall(command) { (output) in
            print(output, terminator: "")
            fflush(stdout)
            
            matchers.forEach { $0.match(output) }
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
        
        guard spawned.waitForExit() == 0 else {
            throw TaskError.commandFailed
        }
    }
    
}

public class DummyServer: Server {
    
    public let id = "DummyServer"
    public let roles: [ServerRole] = []
    public var commandStack: [String] = []
    
    public func _internalExecute(_ command: String) throws {}
    public func _internalCapture(_ command: String) throws -> String { return "" }
    public func _internalExecuteWithOutputMatchers(_ command: String, matchers: [OutputMatcher]) throws {}
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
