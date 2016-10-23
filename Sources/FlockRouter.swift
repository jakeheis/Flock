import SwiftCLI

class FlockRouter: Router {
    
    func route(commands: [Command], aliases: [String: String], arguments: RawArguments) -> Command? {
        let clusterCommands = commands.flatMap { $0 as? ClusterCommand }
        
        guard let commandName = arguments.unclassifiedArguments.first else {
            return nil
        }
        
        let clusterName: String
        let taskName: String?
        if let colonIndex = commandName.value.characters.index(of: ":") {
            clusterName = commandName.value.substring(to: colonIndex)
            taskName = commandName.value.substring(from: commandName.value.index(after: colonIndex))
        } else {
            clusterName = commandName.value
            taskName = nil
        }
        
        commandName.classification = .commandName
        
        guard let command = clusterCommands.first(where: { $0.cluster.name == clusterName }) else {
            return nil
        }
        
        command.taskName = taskName
        
        return command
    }
    
}
