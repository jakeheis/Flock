import SwiftCLI

final class ClusterCommand: OptionCommand {
  
    let name: String
    let signature = "[<task>]"
    let shortDescription = ""
    
    let cluster: Cluster
    var taskName: String?
    
    private let taskExecutor: TaskExecutor
    
    private var printPath = false
    private var environment = "production"
  
    init(cluster: Cluster, taskExecutor: TaskExecutor) {
        self.name = cluster.name
        
        self.cluster = cluster
        self.taskExecutor = taskExecutor
    }
    
    func setupOptions(options: OptionRegistry) {
        options.add(flags: ["-p", "--path"]) {
            self.printPath = true
        }
        options.add(keys: ["-e", "--enviornment"]) { (value) in
            self.environment = value
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        Flock.configure(for: environment)
      
        let call: () throws -> ()
      
        if let taskName = taskName {
            guard let task = cluster.task(named: taskName) else {
                throw CLIError.error("Task \(cluster.name):\(taskName) not found")
            }
            call = { try self.taskExecutor.run(task: task, mode: self.currentMode()) }
        } else {
            call = { try self.taskExecutor.run(cluster: self.cluster, mode: self.currentMode()) }
        }
        
        do {
            try call()
        } catch TaskError.commandFailed {
            throw CLIError.error("A command failed.".red)
        } catch TaskError.error(let string) {
            throw CLIError.error(string.red)
        } catch let error {
            throw error
        }
    }
    
    func currentMode() -> TaskExecutor.Mode {
        if printPath {
            return .print
        }
        
        return .execute
    }
  
}
