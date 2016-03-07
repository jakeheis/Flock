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
        clusters.forEach { use($0) }
    }
    
    public static func addConfiguration(configuration: Configuration, _ time: ConfigurationTime) {
        configurations[time] = configuration
    }
    
    public static func run() {
        let taskExecutor = TaskExecutor(clusters: clusters)
        let commands = clusters.map { ClusterCommand(cluster: $0, taskExecutor: taskExecutor) as CommandType }
        
        CLI.setup(name: "flock", version: "0.0.1", description: "Flock: Automated deployment of your Swift app")
        CLI.router = FlockRouter()
        CLI.registerCommands(commands)
        CLI.go()
    }
    
    // MARK: - Internal
    
    static func configureForEnvironment(environment: String) {
        configurations[.Always]?.configure()
        configurations[.Environment(environment)]?.configure()
    }
    
}

class FlockRouter: RouterType {
    
    func route(commands: [CommandType], arguments: RawArguments) throws -> CommandType {
        let clusterCommands = commands.flatMap { $0 as? ClusterCommand }
        
        guard let commandName = arguments.firstArgumentOfType(.Unclassified) else {
            throw CLIError.Error("Cluster router failed")
        }
        
        let clusterName: String
        let taskName: String?
        if let colonIndex = commandName.characters.indexOf(":") {
            clusterName = commandName.substringToIndex(colonIndex)
            taskName = commandName.substringFromIndex(colonIndex.successor())
        } else {
            clusterName = commandName
            taskName = nil
        }
        
        guard let command = clusterCommands.filter({ $0.cluster.name == clusterName }).first else {
            throw CLIError.Error("Cluster not found")
        }
        
        command.taskName = taskName
        
        return command
    }
    
}
