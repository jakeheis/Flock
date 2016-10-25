import Foundation
import Rainbow
import SwiftCLI

public class Servers {
    
    static var servers: [Server] = []
    
    public static func add(SSHHost: String, roles: [ServerRole]) {
        servers.append(SSHHostServer(SSHHost: SSHHost, roles: roles))
    }
    
    public static func add(docker container: String, roles: [ServerRole]) {
        servers.append(DockerServer(container: container, roles: roles))
    }
    
    // public static func add(IP IP: String, user: String, roles: [ServerRole]) {
    //     servers.append(UserServer(IP: IP, user: user, roles: roles))
    // }
}

public enum ServerRole {
    case app
    case db
    case web
}

public protocol Server: class {
  
    var roles: [ServerRole] { get }
    var commandStack: [String] { get set }
    
    func run(commands: [String], capture: Bool) throws -> String?
    
}

extension Server {
    
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
    
}

public class SSHHostServer: Server {
  
    public let SSHHost: String
    public let roles: [ServerRole]
    
    public var commandStack: [String] = []
    
    public init(SSHHost: String, roles: [ServerRole]) {
        self.SSHHost = SSHHost
        self.roles = roles
    }
    
    public func run(commands: [String], capture: Bool) throws -> String? {
        let finalCommands = commandStack + commands
        let call = finalCommands.joined(separator: "; ")
        
        Logger.logCall(call, on: SSHHost)
        
        let task = Process()
        task.launchPath = "/usr/bin/ssh"
        task.arguments = ["\(SSHHost)", "\(call)"]
        
        if capture {
            task.standardOutput = Pipe()
        }
        
        task.launch()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw TaskError.commandFailed
        }
        
        if let pipe = task.standardOutput as? Pipe {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string = String(data: data, encoding: .utf8)
            return string
        }
        return nil
    }
  
}

public class DockerServer: Server {

    public let container: String
    public let roles: [ServerRole]
    
    public var commandStack: [String] = []
    
    public init(container: String, roles: [ServerRole]) {
        self.container = container
        self.roles = roles
    }
    
    public func run(commands: [String], capture: Bool) throws -> String? {
        let finalCommands = commandStack + commands
        let call = finalCommands.joined(separator: "; ")
        
        let tmpFile = "/tmp/docker_call"
        try call.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        
        let copyTask = Process()
        copyTask.launchPath = "/usr/bin/env"
        copyTask.arguments = ["docker", "cp", tmpFile, "\(container):\(tmpFile)"]
        copyTask.launch()
        copyTask.waitUntilExit()
        
        Logger.logCall(call, on: container)
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["docker", "exec", container, "bash", tmpFile]
        
        if capture {
            task.standardOutput = Pipe()
        }
        
        task.launch()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw TaskError.commandFailed
        }
        
        if let pipe = task.standardOutput as? Pipe {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string = String(data: data, encoding: .utf8)
            return string
        }
        return nil
    }
    
}

public class DummyServer: Server {
    
    public let roles: [ServerRole] = [.app, .db, .web]
    public var commandStack: [String] = []
    
    public func run(commands: [String], capture: Bool) throws -> String? {
        let finalCommands = commandStack + commands
        let call = finalCommands.joined(separator: "; ")
        Logger.logCall(call, on: "Dummy")
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

//extension Process {
//    var commandCall: String {
//        let launch = launchPath ?? ""
//        let args = arguments?.joined(separator: " ") ?? ""
//        return "\(launch) \(args)"
//    }
//}

//class ErrorPipe: Pipe {
//    
//    override init() {
//        super.init()
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("dataAvailable:"), name: NSFileHandleDataAvailableNotification, object: nil)
//        
//        fileHandleForReading.waitForDataInBackgroundAndNotify()
//    }
//    
//    func dataAvailable(note: NSNotification) {
//        var data = fileHandleForReading.availableData
//        while data.length > 0 {
//            print("Got: ", String(data: data, encoding: NSUTF8StringEncoding))
//            data = fileHandleForReading.availableData
//        }
//    }
//    
//}
