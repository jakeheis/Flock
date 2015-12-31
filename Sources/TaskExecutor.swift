class TaskExecutor {
  
    enum Mode {
        case Execute
        case Print
    }
    
    private let scheduler: TaskScheduler
    
    init(clusters: [Cluster]) {
        self.scheduler = TaskScheduler(clusters: clusters)
    }
    
    func runCluster(cluster: Cluster, mode: Mode) {
        for keyedTask in cluster.keyedTasks() {
            runTasksScheduledAtTime(.Before(keyedTask.key), mode: mode)
            runTask(keyedTask, mode: mode)
            runTasksScheduledAtTime(.After(keyedTask.key), mode: mode)
        }
    }
    
    func runTask(keyedTask: KeyedTask, mode: Mode) {
        switch mode {
        case .Execute: keyedTask.task.run()
        case .Print: print(keyedTask.key)
        }
    }
    
    // MARK: - Private
    
    private func runTasksScheduledAtTime(scheduleTime: ScheduleTime, mode: Mode) {
        let tasks = scheduler.scheduledTasksAtTime(scheduleTime)
        for task in tasks {
            runTask(task, mode: mode)
        }
    }
    
}