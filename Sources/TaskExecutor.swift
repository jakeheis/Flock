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
            runTask(keyedTask, mode: mode)
        }
    }
    
    func runTask(keyedTask: KeyedTask, mode: Mode) {
        runTasksScheduledAtTime(.Before(keyedTask.key), mode: mode)
        executeTask(keyedTask, mode: mode)
        runTasksScheduledAtTime(.After(keyedTask.key), mode: mode)
    }
    
    // MARK: - Private
    
    private func executeTask(keyedTask: KeyedTask, mode: Mode) {
        switch mode {
        case .Execute: keyedTask.task.run()
        case .Print: print(keyedTask.key)
        }
    }
    
    private func runTasksScheduledAtTime(scheduleTime: ScheduleTime, mode: Mode) {
        let tasks = scheduler.scheduledTasksAtTime(scheduleTime)
        for task in tasks {
            runTask(task, mode: mode)
        }
    }
    
}