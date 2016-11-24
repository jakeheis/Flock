//
//  SystemdTasks.swift
//  Flock
//
//  Created by Jake Heiser on 11/3/16.
//
//

import Foundation

// MARK: - Default Server functionality

public extension Flock {
    static let Server = SupervisordTasks(provider: DefaultSupervisordProvider()).createTasks()
}

public class DefaultSupervisordProvider: SupervisordProvider {
    public let name = "server"
    public var programName: String {
        return Config.projectName
    }
}

// MARK: - SystemdProvider

public protocol SupervisordProvider {
    var name: String { get }
    var programName: String { get }
    
    func confFileContents(for server: Server) -> String // Defaults to spawning a single instance of your executable with no arguments
}

public extension SupervisordProvider {
    
    // Defaults

    func confFileContents(for server: Server) -> String {
        return [
            "[program:\(programName)]",
            "command=\(Paths.executable)",
            "process_name=%(process_num)s",
            "autostart=false",
            "autorestart=unexpected",
            ""
        ].joined(separator: "\n")
    }
    
    // Add-ons
    
    var confFilePath: String {
        return "/etc/supervisor/conf.d/\(programName).conf"
    }
    
}

// MARK: - SupervisordTasks

public class SupervisordTasks {
    
    let provider: SupervisordProvider
    
    public init(provider: SupervisordProvider) {
        self.provider = provider
    }
    
    public func createTasks() -> [Task] {
        return [
            DependenciesTask(provider: provider),
            WriteConfTask(provider: provider),
            StartTask(provider: provider),
            StopTask(provider: provider),
            RestartTask(provider: provider),
            StatusTask(provider: provider)
        ]
    }
    
}

class SupervisordTask: Task {
    
    var name: String { return "" }
    var hookTimes: [HookTime] { return [] }
    let namespace: String
    let provider: SupervisordProvider
    
    init(provider: SupervisordProvider) {
        self.namespace = provider.name
        self.provider = provider
    }
    
    func run(on server: Server) throws {
        throw TaskError.commandFailed
    }
    
}

class DependenciesTask: SupervisordTask {
    
    override var name: String {
        return "dependencies"
    }
    
    override var hookTimes: [HookTime] {
        return [.after("tools:dependencies")]
    }
    
    override func run(on server: Server) throws {
        try server.execute("apt-get -qq install supervisor")
    }
    
}

class WriteConfTask: SupervisordTask {
    
    override var name: String {
        return "write-conf"
    }
    
    override func run(on server: Server) throws {
        let path = provider.confFilePath
        
        print("Writing \(path)")
        try server.execute("echo \"\(provider.confFileContents(for: server))\" > \(path)")
        try server.execute("supervisorctl reread")
        try server.execute("supervisorctl update")
    }
    
}

class StartTask: SupervisordTask {
    
    override var name: String {
        return "start"
    }
    
    override func run(on server: Server) throws {
        if !server.fileExists(provider.confFilePath) {
            try invoke("\(namespace):write-conf")
        }
        print("Starting \(provider.name)")
        
        try server.execute("supervisorctl start \(provider.programName):*")
    }
    
}

class StopTask: SupervisordTask {
    
    override var name: String {
        return "stop"
    }
    
    override func run(on server: Server) throws {
        print("Stopping \(provider.name)")
        try server.execute("supervisorctl stop \(provider.programName):*")
    }
    
}

class RestartTask: SupervisordTask {
    
    override var name: String {
        return "restart"
    }
    
    override var hookTimes: [HookTime] {
        return [.after("deploy:link")]
    }
    
    override func run(on server: Server) throws {
        if !server.fileExists(provider.confFilePath) {
            try invoke("\(namespace):write-conf")
        }
        
        print("Restarting \(provider.name)")
        try server.execute("supervisorctl restart \(provider.programName):*")
    }
    
}

class StatusTask: SupervisordTask {
    
    override var name: String {
        return "status"
    }
    
    override func run(on server: Server) throws {
        try server.execute("supervisorctl status \(provider.programName):*")
    }
    
}
