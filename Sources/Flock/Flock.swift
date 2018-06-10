//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Rainbow

public class Flock {
    
    public static func run(in env: Environment, _ each: (_ server: Server) throws -> ()) {
        Rainbow.outputTarget = .console
        
        let servers = env.servers.map { Server(ip: $0.ip, port: $0.port, user: $0.user, roles:$0.roles, authMethod: $0.auth)}
        guard !servers.isEmpty else {
            print()
            print("Warning: ".bold.yellow + "no servers specified for environment '\(env.name)'")
            print()
            return
        }
        
        for server in servers {
            do {
                try each(server)
            } catch let error as TaskError {
                error.output()
            } catch let error {
                print("Error: \(error)")
            }
        }
    }
    
}
