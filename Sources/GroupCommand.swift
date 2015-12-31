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
    
    func runTask(task: Task) {
      let hookTime: HookTime = .Before(group.taskToString(task))
      let beforeTasks = Flock.hookableTasks.filter { $0.hookTimes.contains(hookTime) }
      beforeTasks.forEach { runTask($0) }

      task.run()
      
      let hookTimeAfter: HookTime = .After(group.taskToString(task))
      let afterTasks = Flock.hookableTasks.filter { $0.hookTimes.contains(hookTimeAfter) }
      afterTasks.forEach { runTask($0) }
    }
  
}