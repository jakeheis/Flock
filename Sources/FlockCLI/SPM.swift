//
//  SPM.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import Foundation
import SwiftCLI
import Spawn
import PathKit
import Rainbow

class SPM {
    
    enum Error: Swift.Error {
        case processFailed
    }
    
    static func build(silent: Bool = false) throws {
        func modificationDate(of path: Path) -> Date? {
            return (try? FileManager.default.attributesOfItem(atPath: path.description))?[FileAttributeKey.modificationDate] as? Date
        }
        
        if let dependenciesModification = modificationDate(of: Path.flockPackageFile),
            let lastBuilt = modificationDate(of: Path.executable),
            dependenciesModification > lastBuilt {
            
            print("FlockPackage.swift changed -- rebuilding dependencies".yellow)
            try reset()
        }
        
        try executeSPM(arguments: ["build"], silent: silent)
    }
    
    static func update() throws {
        try executeSPM(arguments: ["package", "update"])
        try build()
    }
    
    static func clean() throws {
        try executeSPM(arguments: ["package", "clean"])
    }
    
    static func reset() throws {
        try executeSPM(arguments: ["package", "reset"])
    }
    
    static func dump() throws -> [String: Any] {
        guard let output = try executeSPM(arguments: ["package", "dump-package"], silent: true, inFlock: false),
            let json = try? JSONSerialization.jsonObject(with: output, options: []),
            let dict = json as? [String: Any] else {
            throw Error.processFailed
        }
        
        return dict
    }
    
    static func describe() throws -> String {
        guard let outputData = try executeSPM(arguments: ["package", "describe"], silent: true, inFlock: false),
            let output = String(data: outputData, encoding: .utf8) else {
            throw Error.processFailed
        }
        
        return output
    }
    
    // MARK: - Private
    
    private static var buildProcess: Process?
    
    @discardableResult
    private static func executeSPM(arguments: [String], silent: Bool = false, inFlock: Bool = true) throws -> Data? {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        if inFlock {
            task.currentDirectoryPath = Path.flockDirectory.description
        }
        task.arguments = ["swift"] + arguments
        if silent {
            task.standardOutput = Pipe()
            task.standardError = Pipe()
        }
        task.launch()
        
        buildProcess = task
        
        signal(SIGINT) { (val) in
            SPM.interruptBuild()
            
            // After interrupting build, interrupt this process
            signal(SIGINT, SIG_DFL)
            raise(SIGINT)
        }
        
        task.waitUntilExit()
        
        signal(SIGINT, SIG_DFL)
        
        guard task.terminationStatus == 0 else {
            throw Error.processFailed
        }
        
        if silent {
            let pipe = task.standardOutput as! Pipe
            return pipe.fileHandleForReading.readDataToEndOfFile()
        }
        
        return nil
    }
    
    private static func interruptBuild() {
        buildProcess?.interrupt()
    }
    
}
