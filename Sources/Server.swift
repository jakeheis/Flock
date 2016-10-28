#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation
import Rainbow
import SwiftCLI
import Spawn

public class Servers {
    
    static var servers: [Server] = []
    
    public static func add(ip: String, user: String, roles: [ServerRole]) {
        servers.append(Server(ip: ip, user: user, roles: roles))
    }
    
    public static func add(SSHHost: String, roles: [ServerRole]) {
        servers.append(Server(SSHHost: SSHHost, roles: roles))
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
    
    public convenience init(ip: String, user: String, roles: [ServerRole]) {
        self.init(commandExecutor: UserServer(ip: ip, user: user), roles: roles)
    }
    
    public convenience init(SSHHost: String, roles: [ServerRole]) {
        self.init(commandExecutor: SSHHostServer(SSHHost: SSHHost), roles: roles)
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
    
    // MARK: - Private
    
    private func run(commands: [String], capture: Bool) throws -> String? {
        let finalCommands = commandStack + commands
        let call = finalCommands.joined(separator: "; ")
        
        Logger.logCall(call, on: commandExecutor.id)
        
        let arguments = try commandExecutor.createArguments(for: call)
        
        var captured = ""
        let spawned = try Spawn(args: arguments, output: { (output) in
            print(output)
            captured += output
        })
        
        guard spawned.waitForExit() == 0 else {
            throw TaskError.commandFailed
        }
        
        return captured.isEmpty ? nil : captured
    }
    
}

public protocol ServerCommandExecutor {
    var id: String { get }
    
    func createArguments(for call: String) throws -> [String]
}

// MARK: - UserServer

extension Config {
    public static var SSHKey: String = ""
}

public class UserServer: ServerCommandExecutor {
    
    public var id: String {
        return "\(user)@\(ip)"
    }
    
    public let ip: String
    public let user: String
    
    public init(ip: String, user: String) {
        self.ip = ip
        self.user = user
    }
    
    public func createArguments(for call: String) throws -> [String] {
        guard !Config.SSHKey.isEmpty else {
            throw TaskError.error("You must specify `Config.SSHKey` in your configuration file")
        }
        
        return ["/usr/bin/ssh", "-i", Config.SSHKey, "-l", user, ip, call]
    }
    
}

// MARK: - SSHHostServer

public class SSHHostServer: ServerCommandExecutor {
    
    public let id: String
    
    public init(SSHHost: String) {
        self.id = SSHHost
    }
    
    public func createArguments(for call: String) throws -> [String] {
        return ["/usr/bin/ssh", id, "\(call)"]
    }
    
}

// MARK: - DockerServer

public class DockerServer: ServerCommandExecutor {
    
    public let id: String
    
    public init(container: String) {
        self.id = container
    }
    
    public func createArguments(for call: String) throws -> [String] {
        let tmpFile = "/tmp/docker_call"
        try call.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        
        let copyTask = Process()
        copyTask.launchPath = "/usr/bin/env"
        copyTask.arguments = ["docker", "cp", tmpFile, "\(id):\(tmpFile)"]
        copyTask.launch()
        copyTask.waitUntilExit()
        
        return ["/usr/bin/env", "docker", "exec", id, "bash", tmpFile]
    }
    
}

public class DummyServer: ServerCommandExecutor {
    
    public let id = "DummyServer"
    
    public func createArguments(for call: String) throws -> [String] {
        return ["/bin/echo"]
    }
    
}
