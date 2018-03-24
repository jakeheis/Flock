//
//  FlockCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import SwiftCLI
import PathKit
import Rainbow

protocol FlockCommand: Command {}

extension FlockCommand {
    
    var flockIsInitialized: Bool {
        if !Path.flockfile.exists {
            return false
        }
        if !Path.flockDirectory.exists {
            do {
                try formFlockDirectory()
            } catch {
                return false
            }
        }
        
        do {
            try linkFilesIntoFlock()
        } catch {}
        
        return true
    }
    
    func guardFlockIsInitialized() throws {
        if !flockIsInitialized {
            throw CLI.Error(message: "Error: ".red + "Flock has not been initialized in this directory yet - run `flock --init`")
        }
    }
    
    func formFlockDirectory() throws {
        if Path.flockDirectory.exists {
            return
        }
        
        try Path.flockDirectory.mkpath()
        try Path.mainFile.symlink(Path("..") + Path.flockfile)
    }
    
    func linkFilesIntoFlock() throws {
        for file in try Path.deployDirectory.children() where file.extension == "swift" {
            let link: Path
            if file == Path.flockPackageFile {
                link = Path.flockDirectory + "Package.swift"
            } else {
                link = Path.flockDirectory + file.lastComponent
            }
            if !link.exists {
                try link.symlink(Path("..") + file)
            }
        }
    }
    
}
