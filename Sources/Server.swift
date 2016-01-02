public struct Server {
    public enum Role {
        case App
        case DB
        case Web
    }
  
    public let IP: String
    public let user: String
    public let roles: [Role]
}

extension Config {
    public static var servers: [Server] = []
}
