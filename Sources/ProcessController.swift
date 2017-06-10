//
//  ProcessController.swift
//  Flock
//
//  Created by Jake Heiser on 6/8/17.
//

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
            StatusTask(framework: framework)
        ])
    }
    
    class NohupTask: Task {
        
        let namespace: String
        
        var name: String { return "" }
        var hookTimes: [HookTime] { return [] }
        
        init(framework: ServerFramework) {
            self.namespace = framework.name
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
            try server.execute("nohup \(Paths.executable) > /dev/null 2>&1 &")
            try invoke("server:ps")
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
        let processes = try server.capture("ps aux | grep \".build\"")
        
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

class Supervisord: ProcessController {
    
    public init() {}
    
    func tasks(for framework: ServerFramework) -> TaskSource {
        return TaskSource(tasks:  [
            WriteConfTask(framework: framework),
            StartTask(framework: framework),
            StopTask(framework: framework),
            RestartTask(framework: framework),
            StatusTask(framework: framework)
        ])
    }
    
    class SupervisordTask: Task {
        
        var name: String { return "" }
        var hookTimes: [HookTime] { return [] }
        let namespace: String
        let framework: ServerFramework
        
        init(framework: ServerFramework) {
            self.namespace = framework.name
            self.framework = framework
        }
        
        func run(on server: Server) throws {
            throw TaskError.commandFailed
        }
        
        func executeSupervisorctl(command: String, on server: Server) throws {
            let persmissionsMatcher = OutputMatcher(regex: "Permission denied:") { (match) in
                print("Make sure this user has the ability to run supervisorctl commands -- see https://github.com/jakeheis/Flock#permissions".yellow)
            }
            try server.executeWithOutputMatchers("supervisorctl \(command)", matchers: [persmissionsMatcher])
        }
        
    }
    
    class WriteConfTask: SupervisordTask {
        
        override var name: String {
            return "write-conf"
        }
        
        override func run(on server: Server) throws {
            // Supervisor requires the directories containing the logs to already be created
            let outputParent = parentDirectory(of: Config.outputLog)
            let errorParent = parentDirectory(of: Config.errorLog)
            if let op = outputParent {
                try server.execute("mkdir -p \(op)")
            }
            if let ep = errorParent, errorParent != outputParent {
                try server.execute("mkdir -p \(ep)")
            }
            
            let persmissionsMatcher = OutputMatcher(regex: "Permission denied") { (match) in
                print("Make sure this user has write access to \(Supervisord.confFilePath) -- see https://github.com/jakeheis/Flock#permissions".yellow)
            }
            
            let conf = ConfFile(framework: framework, server: server)
            try server.executeWithOutputMatchers("echo \"\(conf.toString())\" > \(Supervisord.confFilePath)", matchers: [persmissionsMatcher])
            
            try executeSupervisorctl(command: "reread", on: server)
            try executeSupervisorctl(command: "update", on: server)
        }
        
        private func parentDirectory(of path: String) -> String? {
            if let lastPathComponentIndex = path.range(of: "/", options: .backwards, range: nil, locale: nil) {
                return path.substring(to: lastPathComponentIndex.lowerBound)
            }
            return nil
        }
        
    }
    
    class StartTask: SupervisordTask {
        
        override var name: String {
            return "start"
        }
        
        override func run(on server: Server) throws {
            try invoke("\(namespace):write-conf")
            
            try executeSupervisorctl(command: "start \(Config.projectName):*", on: server)
        }
        
    }
    
    class StopTask: SupervisordTask {
        
        override var name: String {
            return "stop"
        }
        
        override func run(on server: Server) throws {
            try executeSupervisorctl(command: "stop \(Config.projectName):*", on: server)
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
            try invoke("\(namespace):write-conf")
            
            try executeSupervisorctl(command: "restart \(Config.projectName):*", on: server)
        }
        
    }
    
    class StatusTask: SupervisordTask {
        
        override var name: String {
            return "status"
        }
        
        override func run(on server: Server) throws {
            try executeSupervisorctl(command: "status \(Config.projectName):*", on: server)
        }
        
    }
    
    private static var confFilePath: String {
        return "/etc/supervisor/conf.d/\(Config.projectName).conf"
    }
    
    public struct ConfFile {
        
        public var programName: String
        public var command: String
        public var processCount: Int
        
        public var processName = "%(process_num)s"
        public var autoStart = true
        public var autoRestart = "unexpected"
        public var stdoutLogfile = Config.outputLog
        public var stderrLogfile = Config.errorLog
        
        public init(framework: ServerFramework, server: Server) {
            self.programName = Config.projectName
            self.command = framework.command
            self.processCount = framework.processCount(for: server)
        }
        
        func toString() -> String {
            let config = [
                "[program:\(programName)]",
                "command=\(command)",
                "process_name=\(processName)",
                "autostart=\(autoStart)",
                "autorestart=\(autoRestart)",
                "stdout_logfile=\(stdoutLogfile)",
                "stderr_logfile=\(stderrLogfile)",
                "numprocs=\(processCount)",
                ""
            ]
            return config.joined(separator: "\n")
        }
        
    }
    
}
