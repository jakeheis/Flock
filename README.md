# Flock

Automated deployment of Swift projects to servers. Once set up, deploying your project is as simple as:

```shell
> flock deploy
```

Flock will clone your project onto your server(s), build it, and start the application (and do anything else you want it to do). Flock already works great with [Vapor](https://github.com/vapor/vapor), [Zewo](https://github.com/Zewo/Zewo), [Perfect](https://github.com/PerfectlySoft/Perfect), and [Kitura](https://github.com/IBM-Swift/Kitura).

Inspired by [Capistrano](https://github.com/capistrano/capistrano).

Table of Contents
=================

   * [Installation](#installation)
       * [Mint](#mint)
       * [Manual](#manual)
   * [Init](#init)
   * [Tasks](#tasks)
       * [Running tasks](#running-tasks)
       * [Writing your own tasks](#writing-your-own-tasks)
   * [Permissions](#permissions)

## Installation
### [Mint](https://github.com/yonaskolb/mint) (recommended)

```bash
mint install jakeheis/Flock
```

### Manual
```bash
git clone https://github.com/jakeheis/Flock
cd Flock
swift build -c release
mv .build/release/flock /usr/bin/local/flock
```

## Init
To start using Flock, run:

```shell
flock init
```

This command creates a `Flock.swift` file in the current directory. After the command completes, you should read through `Flock.swift` and follow the directions located throughout the file.

## Tasks

### Running tasks
You can see the available tasks by running `flock` with no arguments. To run a task, just call `flock <task>`, such as:

```shell
flock deploy # Run the deploy task
```

You can also specify the environment Flock should execute the task in:
```bash
flock deploy --env=production # Same as just running flock deploy
flock deploy --env=staging # Run the deploy task in the staging environment
```

### Writing your own tasks

See the note in `Flock.swift` about how to write your own task. Your task will ultimately run some commands on a `Server` object. Here are some examples of what's possible:

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

Check out [Server.swift](https://github.com/jakeheis/Flock/blob/master/Sources/Flock/Server.swift) to see all of `Server`'s available methods. Also take a look at [Paths.swift](https://github.com/jakeheis/Flock/blob/master/Sources/Flock/Environment.swift) to see the built-in paths for your `server.within` calls.

## Permissions
In general, you should create a dedicated deploy user on your server. [Authentication & Authorisation](http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/#) is a great resource for learning how to do this.

To ensure the `deploy` task succeeds, make sure:
- The deploy user has access to `Config.deployDirectory` (default /var/www)
- The deploy user has access to the `swift` executable

Some additional considerations if you plan to use `supervisord` (which you likely should!):
- The deploy user can run `supervisorctl` commands (see [Using supervisorctl with linux permissions but without root or sudo](https://coffeeonthekeyboard.com/using-supervisorctl-with-linux-permissions-but-without-root-or-sudo-977/) for more info)
- The deploy user has access to the `supervisor` config file (default /etc/supervisor/conf.d/server.conf)
