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
    static let Server = SystemdTasks(provider: DefaultSystemdProvider()).createTasks()
}

public class DefaultSystemdProvider: SystemdProvider {
    public let name = "server"
}

// MARK: - SystemdProvider

public protocol SystemdProvider {
    var name: String { get }
    
    var serviceFileContents: String { get } // Defaults to spawning a single instance of your executable with no arguments
    var serviceName: String { get } // Defaults to Config.projectName
}

public extension SystemdProvider {
    
    // Defaults
    
    var serviceFileContents: String {
        return [
            "[Unit]",
            "Description=\"The \(name) server\"",
            "",
            "[Service]",
            "ExecStart=\"\(Paths.executable)\"",
            "Restart=on-failure",
            ""
        ].joined(separator: "\n")
    }
    
    var serviceName: String {
        return Config.projectName
    }
    
    // Add-ons
    
    var serviceFilePath: String {
        return "/lib/systemd/system/\(serviceName).service"
    }
    
}

// MARK: - SystemdTasks

public class SystemdTasks {
    
    let provider: SystemdProvider
    
    public init(provider: SystemdProvider) {
        self.provider = provider
    }
    
    public func createTasks() -> [Task] {
        return [
            WriteServiceTask(provider: provider),
            StartTask(provider: provider),
            StopTask(provider: provider),
            RestartTask(provider: provider),
            StatusTask(provider: provider)
        ]
    }
    
}

class SystemdTask: Task {
    
    var name: String { return "" }
    var hookTimes: [HookTime] { return [] }
    let namespace: String
    let provider: SystemdProvider
    
    init(provider: SystemdProvider) {
        self.namespace = provider.name
        self.provider = provider
    }
    
    func run(on server: Server) throws {
        throw TaskError.commandFailed
    }
    
}

class WriteServiceTask: SystemdTask {
    
    override var name: String {
        return "write-service"
    }
    
    override func run(on server: Server) throws {
        let path = provider.serviceFilePath
        
        print("Writing \(path)")
        try server.execute("echo \"\(provider.serviceFileContents)\" > \(path)")
        try server.execute("systemctl daemon-reload") // Reload systemctl
    }
    
}

class StartTask: SystemdTask {
    
    override var name: String {
        return "start"
    }
    
    override func run(on server: Server) throws {
        if !server.fileExists(provider.serviceFilePath) {
            try invoke("\(namespace):write-service")
        }
        print("Starting \(provider.name)")
        
        try server.execute("service \(provider.serviceName) start")
    }
    
}

class StopTask: SystemdTask {
    
    override var name: String {
        return "stop"
    }
    
    override func run(on server: Server) throws {
        print("Stopping \(provider.name)")
        try server.execute("service \(provider.serviceName) stop")
    }
    
}

class RestartTask: SystemdTask {
    
    override var name: String {
        return "restart"
    }
    
    override var hookTimes: [HookTime] {
        return [.after("deploy:link")]
    }
    
    override func run(on server: Server) throws {
        if !server.fileExists(provider.serviceFilePath) {
            try invoke("\(namespace):write-service")
        }
        
        print("Restarting \(provider.name)")
        try server.execute("service \(provider.serviceName) restart")
    }
    
}

class StatusTask: SystemdTask {
    
    override var name: String {
        return "status"
    }
    
    override func run(on server: Server) throws {
        try server.execute("service \(provider.serviceName) status")
    }
    
}
