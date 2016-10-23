//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import SwiftCLI

public class Flock {
  
    static var clusters: [Cluster] = []
    static var configurations: [ConfigurationTime: Configuration] = [:]
  
    // MARK: - Public
        
    public static func use(cluster: Cluster) {
        clusters.append(cluster)
    }
    
    public static func use(clusters: [Cluster]) {
        clusters.forEach { use(cluster: $0) }
    }
    
    public static func configure(time: ConfigurationTime, _ configuration: Configuration) {
        configurations[time] = configuration
    }
    
    public static func run() {
        let taskExecutor = TaskExecutor(clusters: clusters)
        let commands = clusters.map { ClusterCommand(cluster: $0, taskExecutor: taskExecutor) as Command }
        
        CLI.setup(name: "flock", version: "0.0.1", description: "Flock: Automated deployment of your Swift app")
        CLI.router = FlockRouter()
        CLI.register(commands: commands)
        let _ = CLI.go()
    }
    
    // MARK: - Internal
    
    static func configure(for environment: String) {
        configurations[.always]?.configure()
        configurations[.environment(environment)]?.configure()
    }
    
}
