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

extension Config {
    public static var deployTo = "/var/www"
    public static var repoURL = ""
}

public class DeployCluster: Cluster {
    public let name = "deploy"
    public let tasks: [Task] = [GitTask()]
}

class GitTask: Task {
    let name = "git"
    
    func run(context: Context) { 
        print("On \(context.server.IP): deploying \(Config.repoURL) to \(Config.deployTo)")
        
        context.server.execute("mkdir HIHello")
    }
}
