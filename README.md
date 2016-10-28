# Flock

Automated deployment of your Swift project to servers. Inspired by [Capistrano](https://github.com/capistrano/capistrano).

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

Flock will create a number of files:

### Flockfile
The Flockfile specifies which tasks and configurations you want Flock to use. In order to use some other tasks, just import the task library and tell Flock to use them:
```swift
import Flock

Flock.use(Flock.Deploy) // Located in Flock
Flock.use(Flock.Tools) // Located in Flock

...
```

`Flock.Deploy` includes the following tasks:
```bash
flock deploy          # Invokes deploy:git, deploy:build, and deploy:link 
flock deploy:git          
flock deploy:build        
flock deploy:link
```
`Flock.Tools` includes tasks which assist in installing the necessary tools for your swift project to run on the server:
```bash
flock tools                 # Invokes tools:dependencies, tools:swift       
flock tools:dependencies  
flock tools:swift
```

### config/deploy/FlockDependencies.json
This file contains your Flock dependencies. To start this only contains `Flock` itself, but if you want to use third party tasks you can add their repositories here. You specify the repository's URL and version (there are three ways to specify version):
```json
{
   "dependencies" : [
       {
           "name" : "https://github.com/jakeheis/Flock",
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
This file contains configuration which will always be used. This is where configuration info which is needed regardless of environment should be placed. Some fields you'll need to update before running any Flock tasks:
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
      Servers.add(ip: "9.9.9.9", user: "user", roles: [.app, .db, .web], authMethod: .key("/path/to/another/key)

      // Or, if you've added your server to your `.ssh/config` file, you can use this shorthand:
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
           "version": "0.0.1"
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
import VaporFlock

Flock.use(Flock.Tools)
Flock.use(Flock.Deploy)
Flock.use(Flock.Vapor)

...

Flock.run()
```

### Server dependencies
If your Swift server uses one of these popular libraries, there are Flock dependencies already available which will hook into `flock deploy` and restart the server after the new release is built.

- [VaporFlock](https://github.com/jakeheis/VaporFlock)
- [PerfectFlock](https://github.com/jakeheis/PerfectFlock)
- [ZewoFlock](https://github.com/jakeheis/ZewoFlock)
- [KituraFlock](https://github.com/jakeheis/KituraFlock)

## Environments

If you want to add additional configuration environments (beyond "staging" and "production), you can do that in the `Flockfile`. Start by running `flock --add-env MyNewEnv` and then modify the `Flockfile` as such:
```swift
...

Flock.configure(.always, with: Always()) // Located at config/deploy/Always.swift
Flock.configure(.env("production"), with: Production()) // Located at config/deploy/Production.swift
Flock.configure(.env("staging"), with: Staging()) // Located at config/deploy/Staging.swift
Flock.configure(.env("test"), with: MyNewEnv()) // Located at config/deploy/MyNewEnv.swift

...
```

# Tasks

### Running tasks
You can see the available tasks by running `flock` with no arguments. To run a task, just call:
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

After running this command, make sure you:

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
