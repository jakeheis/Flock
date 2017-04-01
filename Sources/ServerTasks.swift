//
//  ServerTasks.swift
//  Flock
//
//  Created by Jake Heiser on 3/31/17.
//
//

public extension Flock {
    static let Server = SupervisordTasks(provider: DefaultSupervisordProvider()).createTasks()
}

class DefaultSupervisordProvider: SupervisordProvider {
    let taskNamespace = "server"
    let supervisordName = Config.supervisordName ?? Config.projectName
}

public extension Config {
    static var outputLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.out"
    static var errorLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.err"
    
    static var supervisordName: String? = nil
    
    static var supervisordUser: String? = nil
}
