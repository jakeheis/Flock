//
//  FlockCurassow.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation

class FlockCurassow {
    
    
}

struct Config {
    static var port = "8080"
}

class CurassowGroup: Group {
    let name = "curassow"
    var tasks: [Task] = [
        Start()
    ]
}

class Start: Task {
    
    let name = "start"
    
    func run() {
        
    }
    
}
