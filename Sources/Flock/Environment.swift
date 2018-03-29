//
//  Environment.swift
//  Flock
//
//  Created by Jake Heiser on 3/29/18.
//

import Shout

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
    public let name: String
    public let servers: [ServerLogin]
    public let SSHAuthMethod: SSHAuthMethod?
    public let deployDirectory: String
    
    public init(project: Project, name: String, servers: [ServerLogin], SSHAuthMethod: SSHAuthMethod? = nil, deployDirectory: String = "/var/www") {
        self.project = project
        self.name = name
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
