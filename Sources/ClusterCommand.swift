import SwiftCLI

final class ClusterCommand: OptionCommandType {
  
    let commandName: String
    let commandSignature = "[<task>]"
    let commandShortDescription = ""
    
    private let cluster: Cluster
    private var printPath = false
  
    init(cluster: Cluster) {
      self.commandName = cluster.name
      
      self.cluster = cluster
    }
    
    func setupOptions(options: Options) {
        options.onFlags(["-p", "--path"]) {(flag) in
            self.printPath = true
        }
    }
    
    func execute(arguments: CommandArguments) throws {
        if let taskName = arguments.optionalArgument("task") {
            guard let task = cluster.tasks.filter({ $0.name == taskName }).first else {
                throw CLIError.Error("Task \(cluster.name):\(taskName) not found")
            }
            runTask(task)
        } else {
            for task in cluster.tasks {
              runTask(task)
            }
        }
    }
    
    private func runTask(task: Task) {
      let taskString = cluster.taskToString(task)

      runHooksAtTime(.Before(taskString))
      if printPath {
          print(taskString)
      } else {
          task.run()
      }
      runHooksAtTime(.After(taskString))
    }
    
    private func runHooksAtTime(hookTime: HookTime) {
      let hooks = Flock.hookables.filter { $0.hookTimes.contains(hookTime) }
      for hook in hooks {
        if let task = hook as? Task {
          runTask(task)
        }
      }
    }
  
}