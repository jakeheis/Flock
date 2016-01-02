//
//  DeployCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

extension Flock {
    public static let Deploy = DeployCluster()
}

public class DeployCluster: Cluster {
    public let name = "deploy"
    public let tasks: [Task] = [GitTask()]
    
    // Config
    public var deployTo = "/var/www"
    public var repoURL = ""
}

class GitTask: Task {
    let name = "git"
    
    func run() { 
      print("Deploying \(Flock.Deploy.repoURL) to \(Flock.Deploy.deployTo)")
    }
}
