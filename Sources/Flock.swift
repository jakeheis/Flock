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
    static let scheduler = TaskScheduler()
  
    // MARK: - Public
    
    public static let Default: [Cluster] = [Flock.Deploy]
    
    public static func use(cluster: Cluster) {
        clusters.append(cluster)
    }
    
    public static func use(clusters: [Cluster]) {
        clusters.forEach { use($0) }
    }
    
    public static func run() {
        resolveSchedules()
        CLI.setup(name: "flock", version: "0.0.1", description: "Flock: Automated deployment of your Swift app")
        CLI.registerCommands(buildCommands())
        CLI.go()
    }
    
    // MARK: - Internal
    
    static func resolveSchedules() {
        scheduler.schedule(clusters)
    }
    
    static func buildCommands() -> [CommandType] {
        return clusters.map { ClusterCommand(cluster: $0) }
    }
    
}
