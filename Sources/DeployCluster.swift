//
//  DeployCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

extension Flock {
    static let Deploy = DeployCluster()
}

class DeployCluster: Cluster {
    let name = "deploy"
    let tasks: [Task] = [SSHTask()]
    
    // Config
    public var quickly = false
}

class SSHTask: Task {
    let name = "ssh"
    
    func run() { 
      print("SSHing in ", Flock.Deploy.quickly ? "quickly" : "slowly") 
    }
}
