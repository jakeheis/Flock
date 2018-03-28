//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Rainbow
import Shout
import Foundation

public struct Project {
    public let name: String
    public let repoURL: String
    
    public init(name: String, repoURL: String) {
        self.name = name
        self.repoURL = repoURL
    }
}

public struct Environment {
    public let project: Project
    public let servers: [ServerLogin]
    public let SSHAuthMethod: SSHAuthMethod?
    public let deployDirectory: String
    
    public init(project: Project, servers: [ServerLogin], SSHAuthMethod: SSHAuthMethod? = nil, deployDirectory: String = "/var/www") {
        self.project = project
        self.servers = servers
        self.SSHAuthMethod = SSHAuthMethod
        self.deployDirectory = deployDirectory
    }
}

public extension Environment {
    
    var projectDirectory: String {
        return "\(deployDirectory)/\(project.name)"
    }
    
    var releasesDirectory: String {
        return "\(projectDirectory)/releases"
    }
    
    var currentDirectory: String {
        return "\(projectDirectory)/current"
    }
    
    var nextDirectory: String {
        return "\(projectDirectory)/next"
    }
    
}

public class Flock {
    
    public static func run(in env: Environment, _ each: (_ server: Server) throws -> ()) {
        let servers = env.servers.map { Server(ip: $0.ip, port: $0.port, user: $0.user, roles: [], authMethod: $0.auth)}
        servers.forEach { (server) in
            do {
                try each(server)
            } catch let error as TaskError {
                error.output()
            } catch let error {
                print("Error: \(error)")
            }
        }
    }
    
}
