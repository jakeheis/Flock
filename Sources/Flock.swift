//
//  Flock.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation
import SwiftCLI

class Flock {
    
    public static func buildCommands() -> [CommandType] {
      let groups = [DeployGroup()] // Actually find groups here
      return groups.map { $0.toCommand() }
    }
    
    public func use<T>(type: T.Type) {
        
    }
    
}
