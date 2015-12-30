//
//  main.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation
import SwiftCLI

CLI.setup(name: "flock", version: "0.0.1", description: "Flock: Automated deployment of your Swift app")

CLI.registerCommands(Flock.buildCommands())

CLI.go()
