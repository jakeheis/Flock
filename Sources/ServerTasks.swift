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

public class DefaultSupervisordProvider: SupervisordProvider {
    public let namespace = "server"
    public var programName: String {
        return Config.projectName
    }
}

public extension Config {
    static var outputLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.out"
    static var errorLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.err"
    
    static var supervisordUser: String? = nil
}

