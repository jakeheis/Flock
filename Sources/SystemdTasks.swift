//
//  SystemdTasks.swift
//  Flock
//
//  Created by Jake Heiser on 11/3/16.
//
//

import Foundation

extension Flock {
    static let Zewo = SystemdTasks(provider: ZewoProvider()).createTasks()
}

class ZewoProvider: SystemdProvider {
 
    let name = "Zewo"
    
}

class SystemdTasks {
    
    let provider: SystemdProvider
    
    init(provider: SystemdProvider) {
        self.provider = provider
    }
    
    func createTasks() -> [Task] {
        return [
            StartTask(provider: provider),
            StopTask(provider: provider),
            RestartTask(provider: provider)
        ]
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
        let path = "/lib/systemd/system/\(provider.namespace).service"
        print("Writing \(path)")
        
        try server.execute("echo \"\(generateServiceContents())\" > \(path)")
        
        print("Starting \(provider.name)")
        
        try server.execute("service start \(provider.namespace)")
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
        
        try server.execute("service stop \(provider.namespace)")
    }
    
}

class RestartTask: Task {
    
    let name = "restart"
    let namespace: String
    let provider: SystemdProvider
    
    init(provider: SystemdProvider) {
        self.namespace = provider.namespace
        self.provider = provider
    }
    
    func run(on server: Server) throws {
        try invoke("\(namespace):stop")
        try invoke("\(namespace):start")
    }
    
}


protocol SystemdProvider {
    var name: String { get }
}

extension SystemdProvider {
    var namespace: String {
        return name.lowercased()
    }
}
