//
//  BuildCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import SwiftCLI

class BuildCommand: FlockCommand {
    
    let name = "--build"
    let shortDescription = "Builds Flock in the current directory"
    
    func execute() throws {
        try guardFlockIsInitialized()
        
        try SPM.build()
    }
    
}

class CleanCommand: FlockCommand {
    let name = "--clean"
    let shortDescription = "Cleans Flock's build directory"
    
    func execute() throws {
        try guardFlockIsInitialized()
        
        try SPM.clean()
    }
    
}

class ResetCommand: FlockCommand {
    let name = "--reset"
    let shortDescription = "Cleans Flock's build directory and Packages directory"
    
    func execute() throws {
        try guardFlockIsInitialized()
        
        try SPM.reset()
    }
    
}

class UpdateCommand: FlockCommand {
    let name = "--update"
    let shortDescription = "Updates Flock's dependencies in the current project"
    
    func execute() throws {
        try guardFlockIsInitialized()
        
        try SPM.update()
    }
    
}
