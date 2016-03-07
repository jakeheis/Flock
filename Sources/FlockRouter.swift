import SwiftCLI

class FlockRouter: RouterType {
    
    func route(commands: [CommandType], arguments: RawArguments) throws -> CommandType {
        let clusterCommands = commands.flatMap { $0 as? ClusterCommand }
        
        guard let commandName = arguments.firstArgumentOfType(.Unclassified) else {
            throw CLIError.Error("Cluster router failed")
        }
        
        let clusterName: String
        let taskName: String?
        if let colonIndex = commandName.characters.indexOf(":") {
            clusterName = commandName.substringToIndex(colonIndex)
            taskName = commandName.substringFromIndex(colonIndex.successor())
        } else {
            clusterName = commandName
            taskName = nil
        }
        
        guard let command = clusterCommands.filter({ $0.cluster.name == clusterName }).first else {
            throw CLIError.Error("Task cluster not found")
        }
        
        command.taskName = taskName
        
        return command
    }
    
}
