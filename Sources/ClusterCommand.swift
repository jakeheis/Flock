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
            guard let task = cluster.keyedTasks().filter({ $0.task.name == taskName }).first else {
                throw CLIError.Error("Task \(cluster.name):\(taskName) not found")
            }
            runTask(task)
        } else {
            for task in cluster.keyedTasks() {
              runTask(task)
            }
        }
    }
    
    private func runTask(keyedTask: KeyedTask) {        
        runTasksScheduledAtTime(.Before(keyedTask.key))
        if printPath {
            print(keyedTask.key)
        } else {
            keyedTask.task.run()
        }
        runTasksScheduledAtTime(.After(keyedTask.key))
    }
    
    private func runTasksScheduledAtTime(scheduleTime: ScheduleTime) {
        let tasks = Flock.scheduler.scheduledTasksAtTime(scheduleTime)
        for task in tasks {
            runTask(task)
        }
    }
  
}