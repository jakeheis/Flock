//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import SwiftCLI

public class Flock {
  
    private(set) static var tasks: [Task] = []
    private static var configurations: [ConfigurationTime: Configuration] = [:]
  
    // MARK: - Public
    
    public static func use(_ taskSource: TaskSource) {
        tasks += taskSource.tasks
    }
    
    public static func configure(_ time: ConfigurationTime, with configuration: Configuration) {
        configurations[time] = configuration
    }
    
    public static func run() -> Never {
        TaskExecutor.setup(with: tasks)
        
        let commands = tasks.map { TaskCommand(task: $0) as Command }
        
        CLI.setup(name: "flock", version: "0.0.1", description: "Flock: Automated deployment of your Swift app")
        
        CLI.register(commands: commands)
        
        CLI.helpCommand = HelpCommand()
        CLI.versionCommand = VersionCommand()
        
        CommandAliaser.alias(from: "-h", to: CLI.helpCommand.name)
        CommandAliaser.alias(from: "-v", to: CLI.versionCommand.name)
        
        let result = CLI.go()
        exit(result)
    }
    
    // MARK: - Internal
    
    static func configure(for environment: String) {
        Config.environment = environment
        
        configurations[.always]?.configure()
        configurations[.env(environment)]?.configure()
    }
    
}
