class TaskExecutor {
  
    enum Mode {
        case execute
        case print
    }
    
    private let scheduler: TaskScheduler
    
    init(clusters: [Cluster]) {
        self.scheduler = TaskScheduler(clusters: clusters)
    }
    
    func run(cluster: Cluster, mode: Mode) throws {
        for keyedTask in cluster.keyedTasks() {
            try runTasks(scheduled: .before(keyedTask.key), mode: mode)
            try run(task: keyedTask, mode: mode)
            try runTasks(scheduled: .after(keyedTask.key), mode: mode)
        }
    }
    
    func run(task keyedTask: KeyedTask, mode: Mode) throws {
        switch mode {
        case .execute:
            for server in Servers.servers {
                if Set(server.roles).intersection(Set(keyedTask.task.serverRoles)).isEmpty {
                    continue
                }
                try keyedTask.task.internalRun(on: server, key: keyedTask.key)
            }
        case .print:
            print(keyedTask.key)
        }
    }
    
    // MARK: - Private
    
    private func runTasks(scheduled scheduleTime: ScheduleTime, mode: Mode) throws {
        let tasks = scheduler.scheduledTasks(at: scheduleTime)
        for task in tasks {
            try run(task: task, mode: mode)
        }
    }
    
}
