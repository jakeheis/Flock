import SwiftCLI

final class GroupCommand: CommandType {
  
    let commandName: String
    let commandSignature = "[<task>]"
    let commandShortDescription = ""
    
    private let group: Group
  
    init(group: Group) {
      self.commandName = group.name
      
      self.group = group
    }
    
    func execute(arguments: CommandArguments) throws {
        if let taskName = arguments.optionalArgument("task") {
            guard let task = group.tasks.filter({ $0.name == taskName }).first else {
                throw CLIError.Error("Task \(group.name):\(taskName) not found")
            }
            runTask(task)
        } else {
            for task in group.tasks {
              runTask(task)
            }
        }
    }
    
    private func runTask(task: Task) {
      let taskString = group.taskToString(task)

      runHooksAtTime(.Before(taskString))
      task.run()
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