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
import Shout

public struct ServerLogin {
    public let ip: String
    public let port: Int
    public let user: String
    public let auth: SSHAuthMethod?
    
    public init(ip: String, user: String, auth: SSHAuthMethod? = nil) {
        self.init(ip: ip, port: 22, user: user, auth: auth)
    }
    
    public init(ip: String, port: Int, user: String, auth: SSHAuthMethod? = nil) {
        self.ip = ip
        self.port = port
        self.user = user
        self.auth = auth
    }
    
}

public class Server {

    public enum Role {
        case app
        case db
        case web
    }
    
    public let ip: String
    public let port: Int
    public let user: String
    public let roles: [Role]
    
    private let ssh: SSH
    private var commandStack: [String] = []
    
    public init(ip: String, port: Int, user: String, roles: [Role], authMethod: SSHAuthMethod?) {
        guard let auth = authMethod else {
            print("Error: ".red + "You must either pass in a SSH auth method in your `Server()` initialization or specify `environment.SSHAuthMethod`")
            exit(1)
        }
        
        let ssh: SSH
        do {
            ssh = try SSH(host: ip, port: Int32(port))
            ssh.ptyType = .vanilla
            try ssh.authenticate(username: user, authMethod: auth)
        } catch let error {
            print("Error: ".red + "Couldn't connect to \(user)@\(ip):\(port) (\(error))")
            exit(1)
        }
        
        self.ip = ip
        self.port = port
        self.user = user
        self.roles = roles
        self.ssh = ssh
    }
    
    // MARK: - Command helpers
    
    public func within(_ directory: String, block: () throws -> ()) rethrows {
        commandStack.append("cd \(directory)")
        try block()
        commandStack.removeLast()
    }
    
    public func withPty(_ newType: SSH.PtyType?, block: () throws -> ()) rethrows {
        let oldType = ssh.ptyType
        
        ssh.ptyType = newType
        try block()
        ssh.ptyType = oldType
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
    
    public func commandExists(_ command: String) -> Bool {
        let call = "command -v \(command) >/dev/null 2>&1"
        do {
            try execute(call)
        } catch {
            return false
        }
        return true
    }
    
    // MARK: - Comamnd execution
    
    public func execute(_ command: String) throws {
        let status = try ssh.execute(prepCommand(command))
        guard status == 0 else {
            throw TaskError(status: status)
        }
    }
    
    public func capture(_ command: String) throws -> String {
        let (status, output) = try ssh.capture(prepCommand(command))
        guard status == 0 else {
            if !output.isEmpty {
                print(output)
            }
            throw TaskError(status: status)
        }
        return output
    }
    
    public func executeWithSuggestions(_ command: String, suggestions: [ErrorSuggestion]) throws {
        var captured = ""
        let status = try ssh.execute(prepCommand(command), output: { (output) in
            print(output, terminator: "")
            fflush(stdout)
            captured += output
        })
        guard status == 0 else {
            let suggestion = suggestions.first(where: { $0.matches(captured) })
            if let message = suggestion?.customMessage {
                throw TaskError(message: message, commandSuggestion: suggestion?.command)
            } else {
                throw TaskError(status: status, commandSuggestion: suggestion?.command)
            }
        }
    }
    
    private func prepCommand(_ command: String) -> String {
        let finalCommands = commandStack + [command]
        let call = finalCommands.joined(separator: "; ")
        Logger.logCall(call, on: self)
        return call
    }
    
}

extension Server: CustomStringConvertible {
    
    public var description: String {
        return "\(user)@\(ip):\(port)"
    }
    
}

// MARK: - OutputMatcher

public struct ErrorSuggestion {
    
    let error: String
    let command: String
    let customMessage: String?
    
    init(error: String, command: String, customMessage: String? = nil) {
        self.error = error
        self.command = command
        self.customMessage = customMessage
    }
    
    func matches(_ output: String) -> Bool {
        return output.contains(error)
    }
    
}

public struct TaskError: Error {
    
    public let message: String
    public var commandSuggestion: String?
    
    public init(status: Int32, commandSuggestion: String? = nil) {
        self.init(message: "a command failed (error \(status))", commandSuggestion: commandSuggestion)
    }
    
    public init(message: String, commandSuggestion: String? = nil) {
        self.message = message
        self.commandSuggestion = commandSuggestion
    }
    
    public func output() {
        print()
        print("Error: ".red + message)
        if let commandSuggestion = commandSuggestion {
            print("Try running: ".yellow + commandSuggestion)
        }
        print()
    }
    
}
