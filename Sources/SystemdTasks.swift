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
}

extension SystemdProvider {
    
    var namespace: String {
        return name.lowercased()
    }
    
    var serviceFile: String {
        return "/lib/systemd/system/\(namespace).service"
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
            RestartTask(provider: provider)
        ]
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
        let path = provider.serviceFile
        
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
        if !server.fileExists(provider.serviceFile) {
            try invoke("\(namespace):write-service")
        }
        
        print("Restarting \(provider.name)")
        try server.execute("service \(provider.namespace) restart")
    }
    
}
