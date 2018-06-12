import SwiftCLI

let flock = CLI(name: "flock", version: "0.5.0")

flock.parser = Parser(router: Router())
flock.helpMessageGenerator = HelpMessageGenerator()

flock.commands = [
    InitCommand(),
    ListCommand(),
    CheckCommand(),
    CleanCommand()
]

flock.goAndExit()
