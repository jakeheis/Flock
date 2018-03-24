import SwiftCLI

let flock = CLI(name: "flock")

flock.router = FlockRouter()
flock.helpCommand = nil

flock.commands = [
    InitCommand(),
    BuildCommand(),
    UpdateCommand(),
    CleanCommand(),
    ResetCommand(),
    CreateTaskCommand(),
    NukeCommand(),
    HelpCommand(cli: flock),
    VersionCommand(version: "0.0.1")
]

flock.aliases["help"] = "--help"
flock.aliases["-h"] = "--help"
flock.aliases["-v"] = "--version"

flock.goAndExit()
