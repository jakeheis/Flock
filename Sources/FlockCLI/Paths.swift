//
//  Paths.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import PathKit

extension Path {
    static let flockfile = Path("Flockfile.swift")
    static let deployDirectory = Path("config/deploy")
    static let flockPackageFile = deployDirectory + "FlockPackage.swift"
    
    static let flockDirectory = Path(".flock")
    static let packageFile = flockDirectory + "Package.swift"
    static let mainFile = flockDirectory + "main.swift"
    
    static let buildDirectory = flockDirectory + ".build"
    static let executable = buildDirectory + "debug/flockfile"
}

func createDirectory(at path: Path) throws {
    log(action: "create", description: path.description)
    try path.mkpath()
}

func write(contents: String, to path: Path) throws {
    log(action: "write", description: path.description)
    try path.write(contents)
}

func createLink(at new: Path, pointingTo existing: Path, logPath: Path) throws {
    log(action: "link", description: "\(logPath.description) -> \(new.description)")
    try new.symlink(existing)
}

private func log(action: String, description: String) {
    var paddedAction =  ""
    for _ in 0..<(12 - action.count) {
        paddedAction.append(" ")
    }
    paddedAction.append(action)
    print("\(paddedAction.magenta)   \(description)")
}
