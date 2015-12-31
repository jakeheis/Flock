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
}

class SSHTask: Task {
    let name = "ssh"
    
    func run() { 
      print("SSHing in") 
    }
}
