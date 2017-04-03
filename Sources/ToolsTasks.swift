//
//  ToolsCluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

public extension TaskSource {
    static let tools = TaskSource(tasks:  [
        ToolsTask(),
        DependencyInstallationTask()
    ])
}

private let tools = "tools"

class ToolsTask: Task {
    let name = tools
    
    func run(on server: Server) throws {
        try invoke("tools:dependencies")
    }
}

class DependencyInstallationTask: Task {
    let name = "dependencies"
    let namespace = tools
    
    func run(on server: Server) throws {
        try server.execute("sudo apt-get -qq update")
        try server.execute("sudo apt-get -qq install clang libicu-dev git libpython2.7 libcurl4-openssl-dev")
    }
}
