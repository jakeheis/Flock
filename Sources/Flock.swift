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
    
    public static let Default: [Cluster] = [Flock.Deploy]
    
    public static func use(cluster: Cluster) {
        clusters.append(cluster)
    }
    
    public static func use(clusters: [Cluster]) {
        clusters.forEach { use($0) }
    }
    
    public static func addConfiguration(configuration: Configuration, _ time: ConfigurationTime) {
        configurations[time] = configuration
    }
    
    public static func run() {
        let taskExecutor = TaskExecutor(clusters: clusters)
        let commands = buildCommandsWithTaskExecutor(taskExecutor)
        
        CLI.setup(name: "flock", version: "0.0.1", description: "Flock: Automated deployment of your Swift app")
        CLI.registerCommands(commands)
        CLI.go()
    }
    
    // MARK: - Internal
    
    static func configureForEnvironment(environment: String) {
        configurations[.Always]?.configure()
        configurations[.Environment(environment)]?.configure()
    }
    
    static func buildCommandsWithTaskExecutor(taskExecutor: TaskExecutor) -> [CommandType] {
        return clusters.map { ClusterCommand(cluster: $0, taskExecutor: taskExecutor) }
    }
    
}
