//
//  ServerTasks.swift
//  Flock
//
//  Created by Jake Heiser on 3/31/17.
//
//

public extension TaskSource {
    static let server = TaskSource(tasks: DefaultSupervisordProvider().createTasks())
}

public extension Config {
    static var outputLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.out"
    static var errorLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.err"
    
    static var supervisordName: String? = nil
    static var supervisordUser: String? = nil
}

class DefaultSupervisordProvider: SupervisordProvider {
    let taskNamespace = "server"
    let supervisordName = Config.supervisordName ?? Config.projectName
}
