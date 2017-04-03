//
//  Paths.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

public struct Paths {
    
    public static var projectDirectory: String {
        return "\(Config.deployDirectory)/\(Config.projectName)"
    }
    
    public static var releasesDirectory: String {
        return "\(projectDirectory)/releases"
    }
    
    public static var currentDirectory: String {
        return "\(projectDirectory)/current"
    }
    
    public static var nextDirectory: String {
        return "\(projectDirectory)/next"
    }
    
    public static var executable: String {
        return "\(currentDirectory)/.build/release/\(Config.executableName)"
    }
    
}
