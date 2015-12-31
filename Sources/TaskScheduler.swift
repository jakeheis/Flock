class TaskScheduler {
    
    private var schedule: [ScheduleTime: [KeyedTask]] = [:]
    
    func schedule(clusters: [Cluster]) {
        let allTasks = clusters.flatMap { $0.keyedTasks() }
        
        allTasks.forEach {(keyedTask) in
            guard let scheduledTask = keyedTask.task as? ScheduledTask else {
              return
            }
            
            scheduledTask.scheduledTimes.forEach {(time) in
                var timeTasks = schedule[time] ?? []
                timeTasks.append(keyedTask)
                schedule[time] = timeTasks
            }
        }
    }
  
    func scheduledTasksAtTime(time: ScheduleTime) -> [KeyedTask] {
        return schedule[time] ?? []
    }
  
}
