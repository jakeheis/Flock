//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import SwiftCLI

public class Flock {
  
    static var groups: [Group] = []
    static var hookableTasks: [HookableTask] = []
  
    // MARK: - Public
    
    public static let Default: [Group] = [Flock.Deploy]
    
    public static func use(group: Group) {
        groups.append(group)
        
        for task in group.tasks {
          if let hookableTask = task as? HookableTask {
            hookableTasks.append(hookableTask)
          }
        }
    }
    
    public static func use(groups: [Group]) {
        groups.forEach { use($0) }
    }
    
    public static func run() {
      CLI.setup(name: "flock", version: "0.0.1", description: "Flock: Automated deployment of your Swift app")
      CLI.registerCommands(buildCommands())
      CLI.go()
    }
    
    // MARK: - Internal
    
    static func buildCommands() -> [CommandType] {
      return groups.map { $0.toCommand() }
    }
    
}
