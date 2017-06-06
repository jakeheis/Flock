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
    
    private static var baseEnvironment: Environment?
    private static var keyedEnvironments: [String: Environment] = [:]
  
    // MARK: - Public
    
    public static func use(_ taskSource: TaskSource) {
        tasks += taskSource.tasks
    }
    
    public static func configure(base: Environment, environments: [Environment]) {
        baseEnvironment = base
        
        for env in environments {
            let key = String(describing: type(of: env)).lowercased()
            keyedEnvironments[key] = env
        }
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
    
    static func setup(for environment: String) {
        Config.environment = environment
        
        baseEnvironment?.configure()
        keyedEnvironments[environment]?.configure()
    }
    
}
