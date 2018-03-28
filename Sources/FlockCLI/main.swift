import SwiftCLI

class FlockOptionRecognizer: OptionRecognizer {
    
    func recognizeOptions(from optionRegistry: OptionRegistry, in arguments: ArgumentList) throws {
        // no-op
    }
    
}

let flock = CLI(name: "flock", version: "0.0.1")

flock.router = FlockRouter()
flock.helpMessageGenerator = FlockHelpMessageGenerator()
flock.optionRecognizer = FlockOptionRecognizer()

flock.commands = [
    InitCommand()
]

flock.goAndExit()

/*
 
 // beak: jakeheis/Flock @ 4.0.0
 
 import Flock
 
 // MARK: - Tasks
 
 public func deploy() {
     Flock.run { (server) in
         clone(on: server)
         // swiftenv(on: server)
         build(on: server)
         link(on: server)
     }
 }
 
 public func status() {
     Flock.run { (server) in
 
     }
 }
 
 // MARK: - Implementations
 
 func clone(on server: Server) {
    ...
 }
 
 func build(on server: Server) {
    ...
 }
 
 func link(on server: Server) {
    ...
 }
 
 func swiftenv(on server: Server) {
 
 }
 
 */

/*
 
 import Flock
 
 let flock = Flock()
 
 flock.add(DeployTasks)
 flock.add(SwiftenvTasks)
 
 flock.add("db:migrate") { (server) in
    try server.execute("cat hey")
 }
 
 flock.baseConfiguration = Base()
 flock.configurations = [
    "production": Production(),
    "staging": Staging()
 ]
 
 flock.run()
 
*/
