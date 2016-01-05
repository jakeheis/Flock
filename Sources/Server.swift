public class Servers {
    public static func add(IP IP: String, user: String, roles: [Server.Role]) {
        Config.servers.append(Server(IP: IP, user: user, roles: roles))
    }
}

public struct Server {
    public enum Role {
        case App
        case DB
        case Web
    }
  
    public let IP: String
    public let user: String
    public let roles: [Role]
    
    public init(IP: String, user: String, roles: [Role]) {
        self.IP = IP
        self.user = user
        self.roles = roles
    }
}

extension Config {
    static var servers: [Server] = []
}
