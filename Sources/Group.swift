//
//  Cluster.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import SwiftCLI

public protocol Cluster {
    
    var name: String { get }
    var tasks: [Task] { get }
    
    init()
    
}

extension Cluster {
    func taskToString(task: Task) -> String {
        return "\(name):\(task.name)"
    }
    
}
