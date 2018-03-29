import SwiftCLI
import BeakCore

class FlockOptionRecognizer: OptionRecognizer {
    
    func recognizeOptions(from optionRegistry: OptionRegistry, in arguments: ArgumentList) throws {
        // no-op
    }
    
}

let flock = CLI(name: "flock", version: "0.0.1")

flock.router = FlockRouter()
flock.optionRecognizer = FlockOptionRecognizer()

flock.commands = [
    InitCommand(),
    ListCommand()
]

flock.goAndExit()
