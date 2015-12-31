import SwiftCLI

final class GroupCommand: OptionCommandType {
  
    let commandName: String
    let commandSignature = "[<task>]"
    let commandShortDescription = ""
    
    private let group: Group
    private var printPath = false
  
    init(group: Group) {
      self.commandName = group.name
      
      self.group = group
    }
    
    func setupOptions(options: Options) {
        options.onFlags(["-p", "--path"]) {(flag) in
            self.printPath = true
        }
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