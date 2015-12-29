//
//  main.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation
import SwiftCLI

CLI.setup(name: "flock")

CLI.defaultCommand = RunTaskCommand()
