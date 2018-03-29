//
//  ProcessController.swift
//  Flock
//
//  Created by Jake Heiser on 6/8/17.
//
/*
public protocol ProcessController {
    func tasks(for framework: ServerFramework) -> TaskSource
}

// MARK: - Nohup

public class Nohup: ProcessController {
    
    public init() {}
    
    public func tasks(for framework: ServerFramework) -> TaskSource {
        return TaskSource(tasks: [
            StopTask(framework: framework),
            StartTask(framework: framework),
            RestartTask(framework: framework),
            StatusTask(framework: framework)
        ])
    }
    
    class NohupTask: Task {
        
        let framework: ServerFramework
        
        var namespace: String { return framework.name }
        var name: String { return "" }
        var hookTimes: [HookTime] { return [] }
        
        init(framework: ServerFramework) {
            self.framework = framework
        }
        
        func run(on server: Server) throws {}
        
    }
    
    class StopTask: NohupTask {
        override var name: String { return "stop" }
        override var hookTimes: [HookTime] { return [.before("deploy:link")] }
        
        override public func run(on server: Server) throws {
            if let pid = try Nohup.findServerPid(on: server) {
                try server.execute("kill -9 \(pid)")
            } else {
                print("Server not running")
            }
        }
    }
    
    class StartTask: NohupTask {
        override var name: String { return "start" }
        override var hookTimes: [HookTime] { return [.after("deploy:link")] }
        
        override func run(on server: Server) throws {
            print("Starting server...")
            try server.withPty(nil) {
                try server.execute("nohup \(framework.command) > /dev/null 2>&1 &")
            }
            try invoke("\(namespace):status", on: server)
        }
    }
    
    class RestartTask: NohupTask {
        override var name: String { return "restart" }
        
        override func run(on server: Server) throws {
            try invoke("\(namespace):stop", on: server)
            try invoke("\(namespace):start", on: server)
        }
        
    }
    
    class StatusTask: NohupTask {
        override var name: String { return "status" }
        
        override func run(on server: Server) throws {
            if let pid = try Nohup.findServerPid(on: server) {
                print("Server running as process \(pid)")
            } else {
                print("Server not running")
            }
        }
    }
    
    static private func findServerPid(on server: Server) throws -> String? {
        let processes = try server.capture("ps aux | grep \"\(Paths.executable)\"")
        
        let lines = processes.components(separatedBy: "\n")
        for line in lines where !line.contains("grep") {
            let segments = line.components(separatedBy: " ").filter { !$0.isEmpty }
            if segments.count > 1 {
                return segments[1]
            }
            return segments.count > 1 ? segments[1] : nil
        }
        return nil
    }
    
}

// MARK: - Supervisord

public class Supervisord: ProcessController {
    
    public init() {}
    
    public func tasks(for framework: ServerFramework) -> TaskSource {
        return TaskSource(tasks:  [
            StartTask(framework: framework),
            StopTask(framework: framework),
            RestartTask(framework: framework),
            StatusTask(framework: framework)
        ])
    }
    
    class SupervisordTask: Task {
        
        var namespace: String { return framework.name }
        var name: String { return "" }
        var hookTimes: [HookTime] { return [] }
        
        let framework: ServerFramework
        
        init(framework: ServerFramework) {
            self.framework = framework
        }
        
        func run(on server: Server) throws {}
        
        func executeSupervisorctl(command: String, on server: Server) throws {
            try server.execute("supervisorctl \(command) \(Config.projectName):*")
        }
        
    }
    
    class StartTask: SupervisordTask {
        
        override var name: String { return "start" }
        
        override func run(on server: Server) throws {
            try Supervisord.writeConf(of: framework, to: server)
            
            try executeSupervisorctl(command: "start", on: server)
            try invoke("\(namespace):status", on: server)
        }
        
    }
    
    class StopTask: SupervisordTask {
        
        override var name: String { return "stop" }
        
        override func run(on server: Server) throws {
            try executeSupervisorctl(command: "stop", on: server)
        }
        
    }
    
    class RestartTask: SupervisordTask {
        
        override var name: String { return "restart" }
        override var hookTimes: [HookTime] { return [.after("deploy:link")] }
        
        override func run(on server: Server) throws {
            try Supervisord.writeConf(of: framework, to: server)
            
            try executeSupervisorctl(command: "restart", on: server)
            try invoke("\(namespace):status", on: server)
        }
        
    }
    
    class StatusTask: SupervisordTask {
        
        override var name: String { return "status" }
        
        override func run(on server: Server) throws {
            try executeSupervisorctl(command: "status", on: server)
        }
        
    }
    
    private static func writeConf(of framework: ServerFramework, to server: Server) throws {
        guard server.commandExists("supervisorctl") else {
            throw TaskError(message: "Supervisor must be installed on your system",
                            commandSuggestion: "sudo apt-get install supervisor")
        }
        
        let outputParent = parentDirectory(of: Config.outputLog)
        let errorParent = parentDirectory(of: Config.errorLog)
        if let op = outputParent {
            try server.execute("mkdir -p \(op)")
        }
        if let ep = errorParent, errorParent != outputParent {
            try server.execute("mkdir -p \(ep)")
        }
        
        let processCount = framework.processCount(for: server)
        
        let config = [
            "[program:\(Config.projectName)]",
            "command=\(framework.command)",
            "process_name=%(process_num)s",
            "autostart=true",
            "autorestart=unexpected",
            "stdout_logfile=\(Config.outputLog)",
            "stderr_logfile=\(Config.errorLog)",
            "numprocs=\(processCount)",
            ""
        ].joined(separator: "\n")
        
        let chownLine = "chown=\(server.user)"
        let path = "/etc/supervisor/conf.d/\(Config.projectName).conf"
        let suggestion = ErrorSuggestion(error: "Permission denied",
                                         command: "sudo sed -i '/\\[unix_http_server\\]/a\(chownLine)' /etc/supervisor/supervisord.conf && sudo touch \(path) && sudo chown \(server.user) \(path) && sudo service supervisor restart",
                                         customMessage: "Supervisor must be configured to be used by the user `\(server.user)`")
        try server.executeWithSuggestions("echo \"\(config)\" > \(path)", suggestions: [suggestion])
        
        try server.execute("supervisorctl reread")
        try server.execute("supervisorctl update")
    }
    
    private static func parentDirectory(of path: String) -> String? {
        if let lastPathComponentIndex = path.range(of: "/", options: .backwards, range: nil, locale: nil) {
            return String(path[..<lastPathComponentIndex.lowerBound])
        }
        return nil
    }
    
}
*/
