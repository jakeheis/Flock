//
//  ServerFramework.swift
//  Flock
//
//  Created by Jake Heiser on 6/8/17.
//

public protocol ServerFramework {
    var name: String { get }
    var command: String { get }
    
    func processCount(for server: Server) -> Int
}

public extension ServerFramework {
    var command: String { return Paths.executable }
    
    func processCount(for server: Server) -> Int { return 1 }
}

// MARK: - Generic

public class GenericServerFramework: ServerFramework {
    public let name = "server"
    
    public init() {}
}

// MARK: - Vapor

public class VaporFramework: ServerFramework {
    public let name = "vapor"
    
    public var command: String {
        return Paths.executable + " --env=\(Config.environment)"
    }
    
    public init() {}
}

// MARK: - Zewo

public class ZewoFramework: ServerFramework {
    public let name = "zewo"
    
    public init() {}
    
    public func processCount(for server: Server) -> Int {
        var processCount = 1
        do {
            let processCountString = try server.capture("nproc").trimmingCharacters(in: .whitespacesAndNewlines)
            if let processCountInt = Int(processCountString) {
                processCount = processCountInt
            }
        } catch {}
        return processCount
    }
}

// MARK: - Kitura

public class KituraFramework: ServerFramework {
    public let name = "kitura"
    
    public init() {}
    
    public var command: String {
        return Paths.executable + " --env=\(Config.environment)"
    }
}

// MARK: - Perfect

public extension Config {
    static var perfect = PerfectConfig.self
    
    public struct PerfectConfig {
        public static var ssl: (sslCert: String, sslKey: String)? = nil
        public static var port: UInt16? = nil
        public static var address: String? = nil
        public static var root: String? = nil
        public static var serverName: String? = nil
        public static var runAs: String? = nil
    }
}

public class PerfectFramework: ServerFramework {
    public let name = "perfect"
    
    public var command: String {
        var commandComponents = [Paths.executable]
        if let ssl = Config.perfect.ssl {
            commandComponents.append("--sslcert \(ssl.sslCert)")
            commandComponents.append("--sslkey \(ssl.sslKey)")
        }
        if let port = Config.perfect.port {
            commandComponents.append("--port \(port)")
        }
        if let address = Config.perfect.address {
            commandComponents.append("--address \(address)")
        }
        if let root = Config.perfect.root {
            commandComponents.append("--root \(root)")
        }
        if let serverName = Config.perfect.serverName {
            commandComponents.append("--name \(serverName)")
        }
        if let runAs = Config.perfect.runAs {
            commandComponents.append("--runas \(runAs)")
        }
        return commandComponents.joined(separator: " ")
    }
    
    public init() {}
    
}
