//
//  DeployGroup.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation

class DeployGroup: Group {
    let name = "deploy"
    let tasks: [Task] = [SSHTask()]
}

class SSHTask: Task {
  let name = "ssh"
  
  func run() { print("SSHing in") }
}
