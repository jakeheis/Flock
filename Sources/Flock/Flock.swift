//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

public class Flock {
    
    public static func run(in env: Environment, _ each: (_ server: Server) throws -> ()) {
        let servers = env.servers.map { Server(ip: $0.ip, port: $0.port, user: $0.user, roles:$0.roles, authMethod: $0.auth)}
        servers.forEach { (server) in
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
