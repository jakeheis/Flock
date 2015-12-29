//
//  Task.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

import Foundation

protocol Task {
    var name: String { get }
    
    func run()
}

extension Task {
    func runBefore(task: Task) {
        
    }
    
    func runAfter(task: Task) {
        
    }
}
