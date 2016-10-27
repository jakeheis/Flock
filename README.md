# Flock

Automated deployment of your Swift project to servers. Heavily inspired by [Capistrano](https://github.com/capistrano/capistrano).

## Installation
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

## Usage
### Set up
To start using Flock, run:
```bash
flock --init
```

Flock will create a number of files:

#### Flockfile
The Flockfile specifies which tasks and configurations you want Flock to use. In order to use some other tasks, just import the task library and tell Flock to use them:
```swift
import Flock
import VaporFlock

Flock.use(Flock.Deploy) # Located in Flock
Flock.use(Flock.Tools) # Located in Flock
Flock.use(Flock.Vapor) # Located in VaporFlock

...
```
If the tasks are in a separate library (as `Flock.Vapor` is above), you'll also need to add `VaporFlock` as a dependency as described in the next section.

Additionally, if you want to add additional configuration environments, you can do that here in the `Flockfile`. First run `flock --add-env TestEnvironment` and then modify the `Flockfile`:
```swift
...

Flock.configure(.always, with: Always()) // Located at deploy/Always.swift
Flock.configure(.env("production"), with: Production()) // Located at deploy/Production.swift
Flock.configure(.env("staging"), with: Staging()) // Located at deploy/Staging.swift
Flock.configure(.env("test"), with: TestEnvironment()) // Located at deploy/TestEnvironment.swift

...
```

#### deploy/FlockDependencies.json
This file contains your Flock dependencies. To start this only contains `Flock` itself, but if you want to use third party tasks you can add their repositories here. You specify the repository's URL and version (there are three ways to do this):
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

#### deploy/Always.swift
This file contains configuration which will always be used. This is where configuration info which is needed regardless of environment. Some fields you'll need to update before using Flock:
```
Config.projectName = "ProjectName"
Config.executableName = "ExecutableName"
Config.repoURL = "URL"
```

#### deploy/Production.swift and deploy/Staging.swift
These files contain configuration specific to the production and staging environments, respectively. They will only be run when Flock is executed in their environment (using `flock task -e staging`). Generally this is where you'll want to specify your production and staging servers.

#### deploy/.flock
You can (in general) ignore all the files in this directory.

### Running tasks

You can see the available tasks by just running `flock` with no arguments. Running a task is as easy as:
```bash
flock deploy # Run the deploy task
flock deploy:build # Run the build task located under the deploy namespace
flock tools -e staging # Run the tools task using the staging configuration
flock vapor:start -n # Do a dry-run of the start task located under the Vapor namespace - print the commands that would be executed without actually executing anything
```
