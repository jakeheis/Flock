import SwiftCLI

final class ClusterCommand: OptionCommandType {
  
    let commandName: String
    let commandSignature = "[<task>]"
    let commandShortDescription = ""
    
    let cluster: Cluster
    var taskName: String?
    
    private let taskExecutor: TaskExecutor
    
    private var printPath = false
    private var environment = "production"
  
    init(cluster: Cluster, taskExecutor: TaskExecutor) {
        self.commandName = cluster.name
        
        self.cluster = cluster
        self.taskExecutor = taskExecutor
    }
    
    func setupOptions(options: Options) {
        options.onFlags(["-p", "--path"]) {(flag) in
            self.printPath = true
        }
        options.onKeys(["-e", "--enviornment"]) {(key, value) in
            self.environment = value
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        Flock.configureForEnvironment(environment)
      
        let call: () throws -> ()
      
        if let taskName = taskName {
            guard let task = cluster.taskNamed(taskName) else {
                throw CLIError.Error("Task \(cluster.name):\(taskName) not found")
            }
            call = { try self.taskExecutor.runTask(task, mode: self.currentMode()) }
        } else {
            call = { try self.taskExecutor.runCluster(self.cluster, mode: self.currentMode()) }
        }
        
        do {
            try call()
        } catch TaskError.CommandFailed {
            throw CLIError.Error("A command failed.".red) 
        } catch TaskError.Error(let string) {
            throw CLIError.Error(string.red)
        } catch let error {
            throw error
        }
    }
    
    func currentMode() -> TaskExecutor.Mode {
        if printPath {
            return .Print
        }
        
        return .Execute
    }
  
}