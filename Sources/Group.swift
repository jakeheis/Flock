//
//  Group.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation
import SwiftCLI

public protocol Group {
    
    var name: String { get }
    var tasks: [Task] { get }
    
}

extension Group {
    func taskToString(task: Task) -> String {
        return "\(name):\(task.name)"
    }
}

extension Group {
  func toCommand() -> CommandType {
      let cmd = LightweightCommand(commandName: name)
      cmd.commandSignature = "[<task>]"
      cmd.executionBlock = {(arguments) in
        if let taskName = arguments.optionalArgument("task") {
          guard let task = self.tasks.filter({ $0.name == taskName }).first else {
              throw CLIError.Error("Task \(self.name):\(taskName) not found")
          }
          task.run()
        } else {
          for task in self.tasks {
            task.run()
          }
        }
      }
      return cmd
  }
}
