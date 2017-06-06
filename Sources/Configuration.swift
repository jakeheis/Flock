//
//  Configuration.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

public protocol Environment {
    func configure()
}

// MARK: - Config

public struct Config {}

// MARK: -

public extension Config {
    internal(set) static var environment = ""
}
