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

public extension Config {
    static var SSHAuthMethod: SSH.AuthMethod? = nil
}

public class Server {
    
    public enum Role {
        case app
        case db
        case web
    }
    
    public static var servers: [Server] = []
    
    public static func create(ip: String, user: String, roles: [Role], authMethod: SSH.AuthMethod? = nil) {
        do {
            let server = try Server(ip: ip, user: user, roles: roles, authMethod: authMethod)
            servers.append(server)
        } catch {
            print("Couldn't connect to \(user)@\(ip) (error: \(error))")
            exit(1)
        }
    }
    
    public let ip: String
    public let user: String
    public let roles: [Role]
    public var commandStack: [String] = []
    let session: SSH.Session
    
    public init(ip: String, user: String, roles: [Role], authMethod: SSH.AuthMethod?) throws {
        let session = try SSH.Session(host: ip)
        session.ptyType = .vanilla
        
        let auth: SSH.AuthMethod
        if let authMethod = authMethod {
            auth = authMethod
        } else {
            guard let method = Config.SSHAuthMethod else {
                throw TaskError(message: "You must either pass in a SSH auth method in your `Server.create` call or specify `Config.SSHAuthMethod` in your configuration file")
            }
            auth = method
        }
        
        try session.authenticate(username: user, authMethod: auth)
        
        self.ip = ip
        self.user = user
        self.roles = roles
        self.session = session
    }
    
    // MARK: - Command helpers
    
    public func within(_ directory: String, block: () throws -> ()) rethrows {
        commandStack.append("cd \(directory)")
        try block()
        commandStack.removeLast()
    }
    
    public func withPty(_ newType: SSH.PtyType?, block: () throws -> ()) rethrows {
        let oldType = session.ptyType
        
        session.ptyType = newType
        try block()
        session.ptyType = oldType
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
        let status = try session.execute(prepCommand(command))
        guard status == 0 else {
            throw TaskError(status: status)
        }
    }
    
    public func capture(_ command: String) throws -> String {
        let (status, output) = try session.capture(prepCommand(command))
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
        let status = try session.execute(prepCommand(command), output: { (output) in
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
        return "\(user)@\(ip)"
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
