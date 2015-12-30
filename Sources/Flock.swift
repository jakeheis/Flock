//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation
import SwiftCLI

public class Flock {
  
    var groups: [Group] = []
  
    // MARK: - Public
    
    public static func use(group: Group) {
        groups.append(group)
    }
    
    public static func run() {
      setupDefaults()
      
      CLI.setup(name: "flock", version: "0.0.1", description: "Flock: Automated deployment of your Swift app")
      CLI.registerCommands(buildCommands())
      CLI.go()
    }
    
    // MARK: - Internal
    
    static func setupDefaults() {
        use(DeployGroup)
    }
    
    static func buildCommands() -> [CommandType] {
      let groups = [DeployGroup()] // Actually find groups here
      return groups.map { $0.toCommand() }
    }
    
}
