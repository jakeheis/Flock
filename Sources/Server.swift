import Foundation
import NMSSH

public class Servers {
    
    static var servers: [Server] = []
    
    public static func add(IP IP: String, user: String, roles: [Server.Role]) {
        servers.append(Server(IP: IP, user: user, roles: roles))
    }
}

public class Server {
    public enum Role {
        case App
        case DB
        case Web
    }
  
    public let IP: String
    public let user: String
    public let roles: [Role]
    
    private var commandStack: [String] = []
    
    public init(IP: String, user: String, roles: [Role]) {
        self.IP = IP
        self.user = user
        self.roles = roles
    }
    
    public func within(directory: String, block: () -> ()) {
        commandStack.append("cd \(directory)")
        block()
        commandStack.removeLast()
    }
    
    public func execute(command: String) {
        execute([command])
    }
    
    public func execute(commands: [String]) {
        let config = NMSSHHostConfig()
        config.hostname = IP
        config.user = user
        config.port = 22
        config.identityFiles = [Config.SSHKey]

        let session = NMSSHSession(host: IP, configs: [config], withDefaultPort: 8080, defaultUsername: user)
        session.connect()
        defer { session.disconnect() }
        
        let finalCommands = commandStack + commands
        let finalCommand = finalCommands.joinWithSeparator("; ")
        let call = "bash -c \"\(finalCommand)\""
        
        print("On \(IP): \(call)")
        do {
            try session.channel.execute(call)
        } catch let error as NSError {
            print(error)
        }
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
