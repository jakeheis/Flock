class TaskExecutor {
  
    enum Mode {
        case Execute
        case Print
    }
    
    private let scheduler: TaskScheduler
    
    init(clusters: [Cluster]) {
        self.scheduler = TaskScheduler(clusters: clusters)
    }
    
    func runCluster(cluster: Cluster, mode: Mode) throws {
        for keyedTask in cluster.keyedTasks() {
            try runTasksScheduledAtTime(.Before(keyedTask.key), mode: mode)
            try runTask(keyedTask, mode: mode)
            try runTasksScheduledAtTime(.After(keyedTask.key), mode: mode)
        }
    }
    
    func runTask(keyedTask: KeyedTask, mode: Mode) throws {
        switch mode {
        case .Execute: 
            for server in Servers.servers {
                if Set(server.roles).intersect(Set(keyedTask.task.serverRoles)).isEmpty {
                    continue
                }
                try keyedTask.task.internalRun(server, key: keyedTask.key)
            }
        case .Print:
            print(keyedTask.key)
        }
    }
    
    // MARK: - Private
    
    private func runTasksScheduledAtTime(scheduleTime: ScheduleTime, mode: Mode) throws {
        let tasks = scheduler.scheduledTasksAtTime(scheduleTime)
        for task in tasks {
            try runTask(task, mode: mode)
        }
    }
    
}