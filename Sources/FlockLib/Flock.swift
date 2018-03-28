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
    let name: String
    let repoURL: String
}

public struct Environment {
    let project: Project
    let servers: [ServerLogin]
    let SSHAuthMethod: SSHAuthMethod?
    let deployDirectory: String
    
    public init(project: Project, servers: [ServerLogin], SSHAuthMethod: SSHAuthMethod? = nil, deployDirectory: String = "/var/www") {
        self.project = project
        self.servers = servers
        self.SSHAuthMethod = SSHAuthMethod
        self.deployDirectory = deployDirectory
    }
}

extension Environment {
    
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
    
    public static func go(in env: Environment, _ each: (_ server: Server) throws -> ()) {
        let servers = env.servers.map { Server(ip: $0.ip, port: $0.port, user: $0.user, roles: [], authMethod: $0.auth)}
        servers.forEach { (server) in
            do {
                try each(server)
            } catch let error {
                print("Failed: \(error)")
            }
        }
    }
    
//    public static func serve(ip: String, user: String, roles: [Server.Role], authMethod: SSHAuthMethod? = nil) {
//        servers.append(Server(ip: ip, user: user, roles: roles, authMethod: authMethod))
//    }
//
//    public static func serve(address: Server.Address, user: String, roles: [Server.Role], authMethod: SSHAuthMethod? = nil) {
//        servers.append(Server(address: address, user: user, roles: roles, authMethod: authMethod))
//    }
    
}
