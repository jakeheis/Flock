//
//  SystemdTasks.swift
//  Flock
//
//  Created by Jake Heiser on 11/3/16.
//
//

import Foundation

public protocol SystemdProvider {
    
    var name: String { get }
    
    var serviceFilePath: String { get } // Defaults to /lib/systemd/system/\(namespace).service
    var serviceFileContents: String { get } // Defaults to spawning a single instance of your executable with no arguments
    var additionalTasks: [Task] { get } // Defaults to empty array
    
    func start(on server: Server) throws // Defaults to calling `service (name) start`
    func stop(on server: Server) throws // Defaults to calling `service (name) stop`
    func restart(on server: Server) throws // Defaults to calling `service (name) restart`
    func status(on server: Server) throws // Defaults to calling `service (name) status`
    
}

public extension SystemdProvider {
    
    var namespace: String {
        return name.lowercased()
    }
    
    var serviceFilePath: String {
        return "/lib/systemd/system/\(namespace).service"
    }
    
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
    
    var additionalTasks: [Task] {
        return []
    }
    
    func start(on server: Server) throws {
        try server.execute("service \(namespace) start")
    }
    
    func stop(on server: Server) throws {
        try server.execute("service \(namespace) stop")
    }
    
    func restart(on server: Server) throws {
        try server.execute("service \(namespace) restart")
    }
    
    func status(on server: Server) throws {
        try server.execute("service \(namespace) status")
    }
    
}

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
        ] + provider.additionalTasks
    }
    
}

class WriteServiceTask: Task {
    
    let name = "write-service"
    let namespace: String
    let provider: SystemdProvider
    
    init(provider: SystemdProvider) {
        self.namespace = provider.namespace
        self.provider = provider
    }
    
    func run(on server: Server) throws {
        let path = provider.serviceFilePath
        
        guard !server.fileExists(path) else {
            return
        }
        
        print("Writing \(path)")
        try server.execute("echo \"\(provider.serviceFileContents)\" > \(path)")
    }
    
}

class StartTask: Task {
    
    let name = "start"
    let namespace: String
    let provider: SystemdProvider
    
    init(provider: SystemdProvider) {
        self.namespace = provider.namespace
        self.provider = provider
    }
    
    func run(on server: Server) throws {
        if !server.fileExists(provider.serviceFilePath) {
            try invoke("\(namespace):write-service")
        }
        print("Starting \(provider.name)")
        
        try provider.start(on: server)
    }
    
}

class StopTask: Task {
    
    let name = "stop"
    let namespace: String
    let provider: SystemdProvider
    
    init(provider: SystemdProvider) {
        self.namespace = provider.namespace
        self.provider = provider
    }
    
    func run(on server: Server) throws {
        print("Stopping \(provider.name)")
        try provider.stop(on: server)
    }
    
}

class RestartTask: Task {
    
    let name = "restart"
    let namespace: String
    let provider: SystemdProvider
    
    let hookTimes: [HookTime] = [.after("deploy:link")]
    
    init(provider: SystemdProvider) {
        self.namespace = provider.namespace
        self.provider = provider
    }
    
    func run(on server: Server) throws {
        if !server.fileExists(provider.serviceFilePath) {
            try invoke("\(namespace):write-service")
        }
        
        print("Restarting \(provider.name)")
        try provider.restart(on: server)
    }
    
}

class StatusTask: Task {
    
    let name = "status"
    let namespace: String
    let provider: SystemdProvider
    
    init(provider: SystemdProvider) {
        self.namespace = provider.namespace
        self.provider = provider
    }
    
    func run(on server: Server) throws {
        try provider.status(on: server)
    }
    
}
