# Flock

Automated deployment of Swift projects to servers. Once set up, deploying your project is as simple as:
```
$ flock deploy
```
Flock will clone your project onto your server(s), build it, and start the application (and do anything else you want it to do). Flock already works great with [Vapor](https://github.com/vapor/vapor), [Zewo](https://github.com/Zewo/Zewo), [Perfect](https://github.com/PerfectlySoft/Perfect), and [Kitura](https://github.com/IBM-Swift/Kitura) -- see [below](#server-dependencies) for more information.

Inspired by [Capistrano](https://github.com/capistrano/capistrano).

Table of Contents
=================

   * [Installation](#installation)
       * [Homebrew](#homebrew)
       * [Manual](#manual)
   * [Setup](#setup)
      * [Init](#init)
      * [Environments](#environments)
   * [Tasks](#tasks)
       * [Running tasks](#running-tasks)
       * [Writing your own tasks](#writing-your-own-tasks)
   * [Permissions](#permissions)
   * [Related projects](#related-projects)

# Installation
### Homebrew
```bash
brew install jakeheis/repo/flock
```
### Manual
```bash
git clone https://github.com/jakeheis/FlockCLI
cd FlockCLI
swift build -c release
ln -s .build/release/FlockCLI /usr/bin/local/flock
```

# Setup
## Init
To start using Flock, run:
```bash
flock --init
```
After this command completes, you should follow the instructions Flock prints. Following these instructions should be enough to get your project up and running. For more information about the files Flock creates, read on.

### Flockfile.swift
The Flockfile specifies which tasks and configurations you want Flock to use. In order to use some other tasks, just import the task library and tell Flock to use them:
```swift
import Flock

Flock.use(.deploy)
Flock.use(.swiftenv)
Flock.use(.server)

...
```

`.deploy` includes the following tasks:
```bash
flock deploy          # Invokes deploy:git, deploy:build, and deploy:link 
flock deploy:git      # Clones your project onto your server into a timestamped directory
flock deploy:build    # Builds your project
flock deploy:link     # Links your newly built project directory as the current directory
```
`.server` includes:
```bash
flock server:restart  # Automatically run after deploy:link
flock server:start
flock server:stop
flock server:status
```

`.swiftenv` includes:
```bash
flock swiftenv:install  # Automatically run before deploy:build
```

Running `flock deploy` will:

1. Clone your project onto your server into a timestamped directory (e.g. `/var/www/VaporExample/releases/20161028211084`)
1. Build your project using the version of Swift specified in the .swift-version file
1. Link your built project to the `current` directory (e.g. `/var/www/VaporExample/current`)
1. If you use `.server`, Flock will then use nohup or Supervisord to start your executable and run it as a daemon.

### config/deploy/Base.swift
This file contains configuration which will always be used. This is where config which is needed regardless of environment should be placed. Some fields you'll need to update before running any Flock tasks:
```swift
Config.projectName = "ProjectName"
Config.executableName = "ExecutableName"
Config.repoURL = "URL"
```

### config/deploy/Production.swift and config/deploy/Staging.swift
These files contain configuration specific to the production and staging environments, respectively. They will only be run when Flock is executed in their environment (using `flock deploy staging`). This is where you'll want to specify your production and staging servers. There are multiple ways to specify a server:
```swift
func configure() {
    // For project-wide auth:
    Config.SSHAuthMethod = SSH.Key(
        privateKey: "~/.ssh/key"
    )
    Flock.serve(ip: "9.9.9.9", user: "user", roles: [.app, .db, .web])
      
    // For server-specific auth:
    Flock.serve(ip: "9.9.9.9", user: "user", roles: [.app, .db, .web], authMethod: SSH.Key(
        privateKey: "~/.ssh/key"
    ))
}
```

### config/deploy/FlockPackage.swift
This file contains your Flock dependencies. To start this only contains `Flock` itself (which includes `.deploy`, `.swiftenv`, and `.server`), but if you want to use third party tasks you can add their repositories here:
```swift
let dependencies: [Package.Dependency] = [
    .Package(url: "https://github.com/jakeheis/Flock", majorVersion: 0)
]
```

In your `Flockfile.swift`, notify Flock of your new source of tasks:
```swift
import Flock
import OtherTaskSource

...
Flock.use(.deploy)
Flock.use(.otherTasks)
...

Flock.run()
```

### .flock
You can ignore all the files in this directory. It is used internally by Flock and should not be checked into version control.

## Environments

If you want to add additional configuration environments (beyond "staging" and "production), you can do that in the `Flockfile`. To create a `testing` environment, for example, you would start by creating a file at `config/deploy/Testing.swift`  and then modify the `Flockfile` as such:
```swift
...
// Update this line
Flock.configure(base: Base(), environments: [Production(), Staging(), Testing()]
...
```

# Tasks

### Running tasks
You can see the available tasks by running `flock` with no arguments. To run a task, just call `flock <task>`, such as:
```bash
flock deploy # Run the deploy task
flock deploy:build # Run the deploy:build task
```
You can also specify the environment Flock should execute the task in as the second argument:
```bash
flock deploy production # Same as just running flock deploy
flock deploy staging # Run the deploy task in the staging environment
```

### Writing your own tasks
Start by running:
```bash
flock --create db:migrate # Or whatever you want to call your new task
```

This will create file at config/deploy/DbMigrateTask.swift with the following contents:
```swift
import Flock

public extension TaskSource {
   static let <NameThisGroup> = TaskSource(tasks: [
       MigrateTask()
   ])
}

// Delete if no custom Config properties are needed
extension Config {
   // public static var myVar = ""
}

class MigrateTask: Task {
   let name = "migrate"
   let namespace = "db"

   func run(on server: Server) throws {
      // Do work
   }
}
```

Some of `Server`'s available methods are:
```swift
try server.execute("mysql -v") // Execute a command remotely

let contents = try server.capture("cat myFile") // Execute a command remotely and capture the output

// Execute all commands in this closure within Path.currentDirectory
try server.within(Path.currentDirectory) {
    try server.execute("ls")
    if server.fileExists("anotherFile.txt") { // Check the existence of a file on the server
        try server.execute("cat anotherFile.txt")
    }
}
```

Check out [Server.swift](https://github.com/jakeheis/Flock/blob/master/Sources/Server.swift#L73) to see all of `Server`'s available methods. Also take a look at [Paths.swift](https://github.com/jakeheis/Flock/blob/master/Sources/Paths.swift) to see the built-in paths for your `server.within` calls.

After running `flock --create`, make sure you:

1. Replace \<NameThisGroup\> at the top of your new file with a custom name
1. In your `Flockfile.swift`, add `Flock.use(.whateverINamedIt)`

#### Hooking

If you wish to hook your task onto another task (i.e. always run this task before/after another task, just add an array of hook times to your Task:
```swift
class MigrateTask: Task {
   let name = "migrate"
   let namespace = "db"
   let hookTimes: [HookTime] = [.after("deploy:build")]
   
   func run(on server: Server) throws {
      // Do work
   }
}
```

#### Invoking another task
```swift
func run(on server: Server) throws {
      try invoke("other:task")
}
```
# Permissions
### flock deploy
In general, you should create a dedicated deploy user on your server. [Authentication & Authorisation](http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/#) is a great resource for learning how to do this.

To ensure the `deploy` task succeeds, make sure:
- The deploy user has access to `Config.deployDirectory` (default /var/www)
- The deploy user has access to the `swift` executable

Some additional considerations if you are using `Flock.Server`:
- The deploy user can run `supervisorctl` commands (see [Using supervisorctl with linux permissions but without root or sudo](https://coffeeonthekeyboard.com/using-supervisorctl-with-linux-permissions-but-without-root-or-sudo-977/) for more info)
- The deploy user has access to the `supervisor` config file (default /etc/supervisor/conf.d/server.conf)
# Related projects
#### [FlockCLI](https://github.com/jakeheis/FlockCLI) 
The CLI used to interact with Flock
