//
//  SystemdTasks.swift
//  Flock
//
//  Created by Jake Heiser on 11/3/16.
//
//

public protocol SupervisordProvider {
    var taskNamespace: String { get }
    var supervisordName: String { get }
    
    func confFile(for server: Server) -> SupervisordConfFile // Defaults to spawning a single instance of your executable with no arguments
}

public extension SupervisordProvider {
    
    // Defaults
    
    func confFile(for server: Server) -> SupervisordConfFile {
        return SupervisordConfFile(programName: supervisordName)
    }
    
    // Add-ons
    
    var confFilePath: String {
        return "/etc/supervisor/conf.d/\(supervisordName).conf"
    }
    
}

// MARK: - SupervisordConfFile

public struct SupervisordConfFile {
    
    public var programName: String
    public var command = Paths.executable
    public var processName = "%(process_num)s"
    public var numProcs = 1
    public var autoStart = true
    public var autoRestart = "unexpected"
    public var stdoutLogfile = Config.outputLog
    public var stderrLogfile = Config.errorLog
    
    public init(programName: String) {
        self.programName = programName
    }
    
    func toString() -> String {
        return [
            "[program:\(programName)]",
            "command=\(command)",
            "process_name=\(processName)",
            "numprocs=\(numProcs)",
            "autostart=\(autoStart)",
            "autorestart=\(autoRestart)",
            "stdout_logfile=\(stdoutLogfile)",
            "stderr_logfile=\(stderrLogfile)",
            ""
        ].joined(separator: "\n")
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
        self.namespace = provider.taskNamespace
        self.provider = provider
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

class DependenciesTask: SupervisordTask {
    
    override var name: String {
        return "dependencies"
    }
    
    override var hookTimes: [HookTime] {
        return [.after("tools:dependencies")]
    }
    
    override func run(on server: Server) throws {
        try server.execute("sudo apt-get -qq install supervisor")
        
        if let supervisordUser = Config.supervisordUser {
            let chownLine = "chown=\(supervisordUser)"
            do {
                try server.execute("sudo grep \"\(chownLine)\" < /etc/supervisor/supervisord.conf")
            } catch {
                // grep fails when it has no matches - no matches means line is not in file, so add it
                try server.execute("sudo sed -i '/\\[unix_http_server\\]/a\(chownLine)' /etc/supervisor/supervisord.conf")
            }
            try server.execute("sudo touch \(provider.confFilePath)")
            
            let nonexistentMatcher = OutputMatcher(regex: "invalid user:") { (match) in
                print("\(supervisordUser) (Config.supervisordUser) must already exist on the server before running `flock tools`".yellow)
            }
            try server.executeWithOutputMatchers("sudo chown \(supervisordUser) \(provider.confFilePath)",
                matchers: [nonexistentMatcher])
        }
        
        try server.execute("sudo service supervisor restart")
    }
    
}

class WriteConfTask: SupervisordTask {
    
    override var name: String {
        return "write-conf"
    }
    
    override func run(on server: Server) throws {
        // Supervisor requires the directories containing the logs to already be created
        let outputParent = parentDirectory(of: Config.outputLog)
        let errorParent = parentDirectory(of: Config.outputLog)
        if let op = outputParent {
            try server.execute("mkdir -p \(op)")
        }
        if let ep = errorParent, errorParent != outputParent {
            try server.execute("mkdir -p \(ep)")
        }
        
        let persmissionsMatcher = OutputMatcher(regex: "Permission denied") { (match) in
            print("Make sure this user has write access to \(self.provider.confFilePath) -- see https://github.com/jakeheis/Flock#permissions".yellow)
        }
        try server.executeWithOutputMatchers("echo \"\(provider.confFile(for: server).toString())\" > \(provider.confFilePath)", matchers: [persmissionsMatcher])
        
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
        
        try executeSupervisorctl(command: "start \(provider.supervisordName):*", on: server)
    }
    
}

class StopTask: SupervisordTask {
    
    override var name: String {
        return "stop"
    }
    
    override func run(on server: Server) throws {
        try executeSupervisorctl(command: "stop \(provider.supervisordName):*", on: server)
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
        
        try executeSupervisorctl(command: "restart \(provider.supervisordName):*", on: server)
    }
    
}

class StatusTask: SupervisordTask {
    
    override var name: String {
        return "status"
    }
    
    override func run(on server: Server) throws {
        try executeSupervisorctl(command: "status \(provider.supervisordName):*", on: server)
    }
    
}
