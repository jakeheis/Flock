class TaskScheduler {
    
    private var schedule: [HookTime: [String]] = [:]
    
    init(tasks: [Task]) {
        self.schedule(tasks: tasks)
    }
    
    func schedule(tasks: [Task]) {
        for task in tasks {
            for time in task.hookTimes {
                var timeTasks = schedule[time] ?? []
                timeTasks.append(task.fullName)
                schedule[time] = timeTasks
            }
        }
    }
  
    func scheduledTasks(at time: HookTime) -> [String] {
        return schedule[time] ?? []
    }
  
}
