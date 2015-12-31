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

typealias HookableTask = protocol<Task, Hookable>

public enum HookTime {
    case Before(String)
    case After(String)
}

extension HookTime: Equatable {}

public func == (lhs: HookTime, rhs: HookTime) -> Bool { 
  switch (lhs, rhs) {
    case let (.Before(t1), .Before(t2)) where t1 == t2: return true
    case let (.After(t1), .After(t2)) where t1 == t2: return true
    default: return false
  }
}
