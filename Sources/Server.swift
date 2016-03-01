import Foundation
import Rainbow

public class Servers {
    
    static var servers: [ServerType] = []
    
    public static func add(SSHHost SSHHost: String, roles: [ServerRole]) {
        servers.append(SSHHostServer(SSHHost: SSHHost, roles: roles))
    }
    
    public static func add(IP IP: String, user: String, roles: [ServerRole]) {
        servers.append(UserServer(IP: IP, user: user, roles: roles))
    }
}

public enum ServerRole {
    case App
    case DB
    case Web
}

public protocol ServerType: class {
  
    var roles: [ServerRole] { get }
    var commandStack: [String] { get set }
    
    func execute(commands: [String])
    
}

extension ServerType {
    
    public func within(directory: String, block: () -> ()) {
        commandStack.append("cd \(directory)")
        block()
        commandStack.removeLast()
    }
    
    public func execute(command: String) {
        execute([command])
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
    
    public func execute(commands: [String]) {
        let finalCommands = commandStack + commands
        let finalCommand = finalCommands.joinWithSeparator("; ")
        let call = "\(finalCommand)"
        
        print("On \(SSHHost): \(call)".green)
        
        let task = NSTask()
        task.launchPath = "/usr/bin/ssh"
        task.arguments = ["\(SSHHost)", "\(call)"]
        task.launch()
        task.waitUntilExit()
    }
  
}

public class UserServer: ServerType {
    
    public let IP: String
    public let user: String
    public let roles: [ServerRole]
        
    public var commandStack: [String] = []
    
    public init(IP: String, user: String, roles: [ServerRole]) {
        self.IP = IP
        self.user = user
        self.roles = roles
    }
    
    public func execute(commands: [String]) {
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
    }
    
}

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
