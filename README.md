# Flock

[![Build Status](https://travis-ci.org/jakeheis/Flock.svg?branch=master)](https://travis-ci.org/jakeheis/Flock)

Automated deployment of Swift projects to servers. Once set up, deploying your project is as simple as:
```
$ flock deploy
```
Flock will clone your project onto your server(s), build it, and start the application (and do anything else you want it to do). Flock already works great with [Vapor](https://github.com/vapor/vapor), [Zewo](https://github.com/Zewo/Zewo), [Perfect](https://github.com/PerfectlySoft/Perfect), and [Kitura](https://github.com/IBM-Swift/Kitura) -- see [below](#server-dependencies) for more information.

Check out [this post](https://medium.com/@jakeheis/flock-f54ae40ce48#.nb22b4plo) for a step by step walkthrough of how to use Flock, or read the documentation below.

Inspired by [Capistrano](https://github.com/capistrano/capistrano).

Table of Contents
=================

   * [Installation](#installation)
       * [Homebrew](#homebrew)
       * [Manual](#manual)
   * [Setup](#setup)
      * [Init](#init)
      * [Dependencies](#dependencies)
         * [Server dependencies](#server-dependencies)
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

### Flockfile
The Flockfile specifies which tasks and configurations you want Flock to use. In order to use some other tasks, just import the task library and tell Flock to use them:
```swift
import Flock
import SwiftenvFlock

Flock.use(Flock.Tools)
Flock.use(Flock.Deploy)
Flock.use(Flock.Swiftenv)
Flock.use(Flock.Server)

...
```

`Flock.Deploy` includes the following tasks:
```bash
flock deploy          # Invokes deploy:git, deploy:build, and deploy:link 
flock deploy:git      # Clones your project onto your server into a timestamped directory
flock deploy:build    # Builds your project
flock deploy:link     # Links your newly built project directory as the current directory
```
`Flock.Server` includes:
```bash
flock server:restart  # Hooks after deploy:link
flock server:start
flock server:stop
flock server:status
```
Running `flock deploy` will:

1. Clone your project onto your server into a timestamped directory (e.g. `/var/www/VaporExample/releases/20161028211084`)
1. Build your project
1. Link your built project to the `current` directory (e.g. `/var/www/VaporExample/current`)
1. If you use `Flock.Server`, Flock will then use Supervisord to start your executable and run it as a daemon.

`Flock.Tools` includes tasks which assist in installing the necessary tools for your swift project to run on the server:
```bash
flock tools                 # Invokes tools:dependencies, tools:swift       
flock tools:dependencies    # Installs dependencies necessary for Swift to work
flock tools:swift           # Installs Swift using swiftenv
```

See [SwiftenvFlock](https://github.com/jakeheis/SwiftenvFlock) for more information about `Flock.SwiftenvFlock`

See [Permissions](#permissions) for information regarding which user these tasks should be executed as on the server.

### config/deploy/FlockDependencies.json
This file contains your Flock dependencies. To start this only contains `Flock` itself, but if you want to use third party tasks you can add their repositories here. You specify the repository's URL and version (there are three ways to specify version):
```json
{
   "dependencies" : [
       {
           "name" : "https://github.com/jakeheis/Flock",
           "version": "0.1.1"
       },
       {
           "name" : "https://github.com/jakeheis/SwiftenvFlock",
           "version": "0.0.1"
       },
       {
           "name" : "https://github.com/jakeheis/VaporFlock",
           "major": 0
       },
       {
           "name" : "https://github.com/someone/something",
           "major": 2,
           "minor": 1
       }
   ]
}
```
See the [dependencies](#dependencies) section below for more information on third party dependencies.
### config/deploy/Always.swift
This file contains configuration which will always be used. This is where config which is needed regardless of environment should be placed. Some fields you'll need to update before running any Flock tasks:
```
Config.projectName = "ProjectName"
Config.executableName = "ExecutableName"
Config.repoURL = "URL"
```

### config/deploy/Production.swift and config/deploy/Staging.swift
These files contain configuration specific to the production and staging environments, respectively. They will only be run when Flock is executed in their environment (using `flock task -e staging`). Generally this is where you'll want to specify your production and staging servers. There are multiple ways to specify a server:
```swift
func configure() {
      // For project-wide auth:
      Config.SSHAuthMethod = .key("/path/to/my/key")
      Servers.add(ip: "9.9.9.9", user: "user", roles: [.app, .db, .web])
      
      // For server-specific auth:
      Servers.add(ip: "9.9.9.9", user: "user", roles: [.app, .db, .web], authMethod: .key("/path/to/another/key"))

      // Or, if you've added your server to your .ssh/config file, you can use this shorthand:
      Servers.add(SSHHost: "NamedServer", roles: [.app, .db, .web])
}
```

### .flock
You can (in general) ignore all the files in this directory.

## Dependencies

To add a third party dependency, you first add the repository to config/deploy/FlockDependencies.json:
```json
{
   "dependencies" : [
       {
           "name" : "https://github.com/jakeheis/Flock",
           "version": "0.1.0"
       },
       {
           "name" : "https://github.com/jakeheis/VaporFlock",
           "major": 0,
           "minor": 0
       }
   ]
}
```

In your Flockfile, notify Flock of your new source of tasks:
```swift
import Flock
import SwiftenvFlock
import VaporFlock

Flock.use(Flock.Tools)
Flock.use(Flock.Deploy)
Flock.use(Flock.Swiftenv)
Flock.use(Flock.Vapor)

...

Flock.run()
```

### Server dependencies

If you just want Flock to restart your app after deployment, the built-in `Flock.Server` tasks will do that for you, so you don't need to change anything. If, however, your Swift server uses one of these popular libraries, there are Flock dependencies which add features on top of `Flock.Server` particular to their respective libraries:

- [VaporFlock](https://github.com/jakeheis/VaporFlock)
- [PerfectFlock](https://github.com/jakeheis/PerfectFlock)
- [ZewoFlock](https://github.com/jakeheis/ZewoFlock)
- [KituraFlock](https://github.com/jakeheis/KituraFlock)

## Environments

If you want to add additional configuration environments (beyond "staging" and "production), you can do that in the `Flockfile`. To create a `testing` environment, for example, you would start by running `flock --add-env Testing` and then modify the `Flockfile` as such:
```swift
...

Flock.configure(.always, with: Always()) // Located at config/deploy/Always.swift
Flock.configure(.env("production"), with: Production()) // Located at config/deploy/Production.swift
Flock.configure(.env("staging"), with: Staging()) // Located at config/deploy/Staging.swift
Flock.configure(.env("testing"), with: Testing()) // Located at config/deploy/Testing.swift

...
```

# Tasks

### Running tasks
You can see the available tasks by running `flock` with no arguments. To run a task, just call `flock <task>`, such as:
```bash
flock deploy # Run the deploy task
flock deploy:build # Run the build task located under the deploy namespace
```
Passing the `-n` flag tells Flock to do a dry-run, meaning to only print commands without actually executing any.
```bash
flock vapor:start -n # Do a dry-run of the start task located under the vapor namespace
```
You can also pass the `-e <env>` key, telling Flock to run the task in a certain environment:
```bash
flock tools -e staging # Run the tools task in the staging environment
```

### Writing your own tasks
Start by running:
```bash
flock --create db:migrate # Or whatever you want to call your new task
```

This will create file at config/deploy/DbMigrateTask.swift with the following contents:
```swift
import Flock

extension Flock {
   public static let <NameThisGroup>: [Task] = [
       MigrateTask()
   ]
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
1. In your Flockfile, add `Flock.use(WhateverINamedIt)`

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

Running `flock tools` can take care of most of these things for you, but you must set `Config.supervisordUser` in `config/deploy/Always.swift` to your dedicated deploy user *before* running `flock tools`.
### flock tools
The `tools` task must be run as the root user. This means that in `config/deploy/Production.swift`, in your `Servers.add` call you must pass `user: "root"`. As mentioned above, it is not a good idea to deploy with `user: "root"`, so you should only call `flock tools` with this configuration and then change it to make calls with your dedicated deploy user rather then the root user.
# Related projects
#### [FlockCLI](https://github.com/jakeheis/FlockCLI) 
The CLI used to interact with Flock
#### [SwiftenvFlock](https://github.com/jakeheis/SwiftenvFlock)
Integration of Swiftenv into Flock deployments
#### [VaporFlock](https://github.com/jakeheis/VaporFlock)
Automated deployment of your Vapor server using Flock
#### [PerfectFlock](https://github.com/jakeheis/PerfectFlock)
Automated deployment of your Perfect server using Flock
#### [KituraFlock](https://github.com/jakeheis/KituraFlock)
Automated deployment of your Kitura server using Flock
#### [ZewoFlock](https://github.com/jakeheis/ZewoFlock)
Automated deployment of your Zewo server using Flock
#### [VaporExample](https://github.com/jakeheis/VaporExample)
An example of a Vapor server deployed with Flock
