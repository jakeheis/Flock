//
//  ServerTasks.swift
//  Flock
//
//  Created by Jake Heiser on 3/31/17.
//
//

public extension TaskSource {
    // Generic
    
    static let server = TaskSource(tasks: DefaultSupervisordProvider().createTasks())
    
    // Specialized
    
    static let vapor = TaskSource(tasks: VaporSupervisord().createTasks())
    static let zewo = TaskSource(tasks: ZewoSupervisord().createTasks())
    static let perfect = TaskSource(tasks: (PerfectSupervisord().createTasks() + [PerfectToolsTask()]))
    static let kitura = TaskSource(tasks: KituraSupervisord().createTasks() + [KituraToolsTask()])
}

// MARK: - Default

public extension Config {
    static var outputLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.out"
    static var errorLog = "/var/log/supervisor/%(program_name)s-%(process_num)s.err"
    
    static var supervisordName: String? = nil
    static var supervisordUser: String? = nil
}

class DefaultSupervisordProvider: SupervisordProvider {
    let taskNamespace = "server"
}

// MARK: - Vapor

class VaporSupervisord: SupervisordProvider {
    
    let taskNamespace = "vapor"
    
    func confFile(for server: Server) -> SupervisordConfFile {
        var file = SupervisordConfFile(programName: supervisordName)
        file.command += " --env=\(Config.environment)"
        return file
    }
    
}

// MARK: - Zewo

class ZewoSupervisord: SupervisordProvider {
    let taskNamespace = "zewo"
    
    func confFile(for server: Server) -> SupervisordConfFile {
        var processCount = 1
        do {
            if let processCountString = try server.capture("nproc")?.trimmingCharacters(in: .whitespacesAndNewlines),
                let processCountInt = Int(processCountString) {
                processCount = processCountInt
            }
        } catch {}
        
        var file = SupervisordConfFile(programName: supervisordName)
        file.add("numprocs=\(processCount)")
        return file
    }
}

// MARK: - Perfect

public extension Config {
    static var perfect = PerfectConfig.self
    
    public struct PerfectConfig {
        public static var ssl: (sslCert: String, sslKey: String)? = nil
        public static var port: UInt16? = nil
        public static var address: String? = nil
        public static var root: String? = nil
        public static var serverName: String? = nil
        public static var runAs: String? = nil
    }
}

class PerfectSupervisord: SupervisordProvider {
    
    let taskNamespace = "perfect"
    
    func confFile(for server: Server) -> SupervisordConfFile {
        var confFile = SupervisordConfFile(programName: supervisordName)
        
        var commandComponents = [Paths.executable]
        if let ssl = Config.perfect.ssl {
            commandComponents.append("--sslcert \(ssl.sslCert)")
            commandComponents.append("--sslkey \(ssl.sslKey)")
        }
        if let port = Config.perfect.port {
            commandComponents.append("--port \(port)")
        }
        if let address = Config.perfect.address {
            commandComponents.append("--address \(address)")
        }
        if let root = Config.perfect.root {
            commandComponents.append("--root \(root)")
        }
        if let serverName = Config.perfect.serverName {
            commandComponents.append("--name \(serverName)")
        }
        if let runAs = Config.perfect.runAs {
            commandComponents.append("--runas \(runAs)")
        }
        confFile.command = commandComponents.joined(separator: " ")
        
        return confFile
    }
    
}

public class PerfectToolsTask: Task {
    public let name = "tools"
    public let namespace = "perfect"
    public let hookTimes: [HookTime] = [.after("tools:dependencies")]
    
    public func run(on server: Server) throws {
        print("Installing Perfect dependencies")
        try server.execute("sudo apt-get -qq install openssl libssl-dev uuid-dev")
    }
}

// MARK: - Kitura

class KituraSupervisord: SupervisordProvider {
    
    let taskNamespace = "kitura"
    
    func confFile(for server: Server) -> SupervisordConfFile {
        var file = SupervisordConfFile(programName: supervisordName)
        file.command += " --env=\(Config.environment)"
        return file
    }
    
}

public class KituraToolsTask: Task {
    public let name = "tools"
    public let namespace = "kitura"
    public let hookTimes: [HookTime] = [.after("tools:dependencies")]
    
    public func run(on server: Server) throws {
        print("Installing Kitura dependencies")
        try server.execute("sudo apt-get -qq install libssl-dev")
    }
}
