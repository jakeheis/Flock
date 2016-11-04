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
            "Description=\"Starts the \(name) server\"",
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
        try server.execute("echo \"\(generateServiceContents())\" > \(path)")
    }
    
    func generateServiceContents() -> String {
        return [
            "[Unit]",
            "Description=\"Starts the \(provider.name) server\"",
            "",
            "[Service]",
            "ExecStart=\"\(Paths.executable)\"",
            "Restart=on-failure",
            ""
        ].joined(separator: "\n")
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
        try server.execute("service \(provider.namespace) start")
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
        try server.execute("service \(provider.namespace) stop")
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
        try server.execute("service \(provider.namespace) restart")
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
        try server.execute("service \(provider.namespace) status")
    }
    
}
