import SwiftCLI

final class ClusterCommand: OptionCommandType {
  
    let commandName: String
    let commandSignature = "[<task>]"
    let commandShortDescription = ""
    
    private let cluster: Cluster
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
      
        if let taskName = arguments.optionalArgument("task") {
            guard let task = cluster.keyedTasks().filter({ $0.task.name == taskName }).first else {
                throw CLIError.Error("Task \(cluster.name):\(taskName) not found")
            }
            try taskExecutor.runTask(task, mode: currentMode())
        } else {
            try taskExecutor.runCluster(cluster, mode: currentMode())
        }
    }
    
    func currentMode() -> TaskExecutor.Mode {
        if printPath {
            return .Print
        }
        
        return .Execute
    }
  
}