//
//  ServerTasks.swift
//  Flock
//
//  Created by Jake Heiser on 3/31/17.
//
//

public extension TaskSource {
    static var server: TaskSource {
        return Config.processController.tasks(for: Config.serverFramework)
    }
}

public extension Config {
    static var serverFramework: ServerFramework = GenericServerFramework()
    static var processController: ProcessController = Nohup()
    
    static var outputLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.out"
    static var errorLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.err"
}
