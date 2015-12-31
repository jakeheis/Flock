//
//  Task.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

public protocol Task {
    var name: String { get }
    
    func run()
}

public protocol Hookable {
    var hookTimes: [HookTime] { get }
}

public enum HookTime {
    case Before(String)
    case After(String)
}
