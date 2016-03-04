import Foundation
import Rainbow
import SwiftCLI

public class Servers {
    
    static var servers: [ServerType] = []
    
    public static func add(SSHHost SSHHost: String, roles: [ServerRole]) {
        servers.append(SSHHostServer(SSHHost: SSHHost, roles: roles))
    }
    
    public static func add(dockerContainer container: String, roles: [ServerRole]) {
        servers.append(DockerServer(container: container, roles: roles))
    }
    
    // public static func add(IP IP: String, user: String, roles: [ServerRole]) {
    //     servers.append(UserServer(IP: IP, user: user, roles: roles))
    // }
}

public enum ServerRole {
    case App
    case DB
    case Web
}

public protocol ServerType: class {
  
    var roles: [ServerRole] { get }
    var commandStack: [String] { get set }
    
    func execute(commands: [String], capture: Bool) throws -> String?
    
}

extension ServerType {
    
    public func within(directory: String, block: () throws -> ()) rethrows {
        commandStack.append("cd \(directory)")
        try block()
        commandStack.removeLast()
    }
    
    public func fileExists(file: String) -> Bool {
        let call = "test -f \(file)"
        do {
            try execute(call)
        } catch {
            return false
        }
        return true
    }
    
    public func directoryExists(directory: String) -> Bool {
        let call = "test -d \(directory)"
        do {
            try execute(call)
        } catch {
            return false
        }
        return true
    }
    
    public func execute(command: String) throws {
        try execute([command], capture: false)
    }
    
    public func capture(command: String) throws -> String? {
        return try execute([command], capture: true)
    }
    
}

public class SSHHostServer: ServerType {
  
    public let SSHHost: String
    public let roles: [ServerRole]
    
    public var commandStack: [String] = []
    
    public init(SSHHost: String, roles: [ServerRole]) {
        self.SSHHost = SSHHost
        self.roles = roles
    }
    
    public func execute(commands: [String], capture: Bool) throws -> String? {
        let finalCommands = commandStack + commands
        let finalCommand = finalCommands.joinWithSeparator("; ")
        let call = "\(finalCommand)"
        
        print("On \(SSHHost): \(call)".green)
        
        let task = NSTask()
        task.launchPath = "/usr/bin/ssh"
        task.arguments = ["\(SSHHost)", "\(call)"]
        
        if capture {
            task.standardOutput = NSPipe()
        }
        
        task.launch()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw TaskError.CommandFailed
        }
        
        if let pipe = task.standardOutput as? NSPipe {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string = String(data: data, encoding: NSUTF8StringEncoding)
            return string
        }
        return nil
    }
  
}

public class DockerServer: ServerType {

    public let container: String
    public let roles: [ServerRole]
    
    public var commandStack: [String] = []
    
    public init(container: String, roles: [ServerRole]) {
        self.container = container
        self.roles = roles
    }
    
    public func execute(commands: [String], capture: Bool) throws -> String? {
        let finalCommands = commandStack + commands
        let finalCommand = finalCommands.joinWithSeparator("; ")
        let call = "\(finalCommand)"
        
        let tmpFile = "/tmp/docker_call"
        try call.writeToFile(tmpFile, atomically: true, encoding: NSUTF8StringEncoding)
        
        let copyTask = NSTask()
        copyTask.launchPath = "/usr/bin/env"
        copyTask.arguments = ["docker", "cp", tmpFile, "\(container):\(tmpFile)"]
        copyTask.launch()
        copyTask.waitUntilExit()
        
        print("On \(container): \(call)".green)
        
        let task = NSTask()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["docker", "exec", container, "bash", tmpFile]
        
        if capture {
            task.standardOutput = NSPipe()
        }
        
        task.launch()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw TaskError.CommandFailed
        }
        
        if let pipe = task.standardOutput as? NSPipe {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string = String(data: data, encoding: NSUTF8StringEncoding)
            return string
        }
        return nil
    }
    
}

/*public class UserServer: ServerType {
    
    public let IP: String
    public let user: String
    public let roles: [ServerRole]
        
    public var commandStack: [String] = []
    
    public init(IP: String, user: String, roles: [ServerRole]) {
        self.IP = IP
        self.user = user
        self.roles = roles
    }
    
    public func execute(commands: [String], capture: Bool) -> String? {
        // let config = NMSSHHostConfig()
        // config.hostname = IP
        // config.user = user
        // config.port = 22
        // config.identityFiles = [Config.SSHKey]
        // 
        // let session = NMSSHSession(host: IP, configs: [config], withDefaultPort: 8080, defaultUsername: user)
        // session.connect()
        // defer { session.disconnect() }
        
        // let finalCommands = commandStack + commands
        // let finalCommand = finalCommands.joinWithSeparator("; ")
        // let call = "\(finalCommand)"
        
        // print("On \(IP): \(call)")
        // do {
        //     try session.channel.execute(call)
        // } catch let error as NSError {
        //     print(error)
        // }
        return nil
    }
    
}*/

extension Config {
    public static var SSHKey: String = ""
}

extension NSTask {
    var commandCall: String {
        let launch = launchPath ?? ""
        let args = arguments?.joinWithSeparator(" ") ?? ""
        return "\(launch) \(args)"
    }
}
