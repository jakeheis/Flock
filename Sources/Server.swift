import Foundation

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
        let finalCommands = commandStack + commands
        let finalCommand = finalCommands.joinWithSeparator("; ")
        
        let task = NSTask()
        task.launchPath = "/usr/bin/ssh"
        task.arguments = ["-i \(Config.SSHKey)", "\(user)@\(IP)", "bash -c '\(finalCommand)'"]
        
        print("On \(IP): \(task.commandCall)")
        
        task.launch()
        task.waitUntilExit()
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
