//
//  InitCommand.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/26/16.
//
//

import Foundation
import SwiftCLI
import Rainbow
import PathKit
import Spawn

class InitCommand: FlockCommand {
  
    let name = "--init"
    let shortDescription = "Initializes Flock in the current directory"
    
    func execute() throws {
        guard !flockIsInitialized else {
            throw CLI.Error(message: "Error: ".red + "Flock has already been initialized")
        }
        
        try checkExisting()
        
        try createFiles()
        
        try updateGitIgnore()
        
        try build()
        
        print("Successfully initialized Flock!".green)
        
        printInstructions()
    }
    
    func checkExisting() throws {
        for path in [Path.flockDirectory, Path.flockfile] {
            if path.exists {
                throw CLI.Error(message: "\(path) must not already exist".red)
            }
        }
    }
    
    func createFiles() throws {
        print("Creating Flock files...".yellow)
        
        try write(contents: flockfileDefault(), to: Path.flockfile)
        
        try createDirectory(at: Path.deployDirectory)
        
        try create(env: "base", defaults: baseDefaults())
        try create(env: "production", defaults: envConfigDefaults())
        try create(env: "staging", defaults: envConfigDefaults())
        
        try write(contents: packageDefault(), to: Path.flockPackageFile)
        
        try formFlockDirectory()
        try linkFilesIntoFlock()
        
        print("Successfully created Flock files".green)
    }
    
    func build() throws {
        print("Downloading and building dependencies...".yellow)
        // Only doing this to build dependencies; actual build will fail
        do {
            try SPM.build(silent: true)
        } catch {}
        print("Successfully downloaded dependencies".green)
    }
    
    func updateGitIgnore() throws {
        let gitIgnorePath = Path(".gitignore")
        
        guard gitIgnorePath.exists else {
            return
        }
        
        print("Adding Flock files to .gitignore...".yellow)
        
        let appendText = [
            "",
            "# Flock",
            Path.flockDirectory.description,
            ""
        ].joined(separator: "\n")
        
        let contents: String? = try? gitIgnorePath.read()
        if contents == nil || !contents!.contains("# Flock") {
            guard let gitIgnore = OutputStream(toFileAtPath: gitIgnorePath.description, append: true) else {
                throw CLI.Error(message: "Couldn't open .gitignore stream")
            }
            gitIgnore.open()
            gitIgnore.write(appendText, maxLength: appendText.count)
            gitIgnore.close()
        }
        
        print("Successfully added Flock files to .gitignore".green)
    }
    
    func printInstructions() {
        print()
        print("Follow these steps to finish setting up Flock:".cyan)
        print("1. Add `exclude: [\"Flockfile.swift\"]` to the end of your Package.swift")
        print("2. Update the required fields in \(Path.deployDirectory)/Always.swift")
        print("3. Add your servers to \(Path.deployDirectory)/Production.swift and \(Path.deployDirectory)/Staging.swift")
        print()
    }
    
    // MARK: - Helpers
    
    private func create(env: String, defaults: [String]) throws {
        let fileName = "\(env.capitalized).swift"
        let filePath = Path.deployDirectory + fileName
        
        var lines = [
            "import Flock",
            "import SSH",
            "",
            "class \(env.capitalized): Environment {",
            "\tfunc configure() {"
        ]
        lines += defaults.map { "\t\t\($0)" }
        lines += [
            "\t}",
            "}",
            ""
        ]
        let text = lines.joined(separator: "\n")
        
        try write(contents: text, to: filePath)
    }
    
    // MARK: - Defaults
  
    private func flockfileDefault() -> String {
      return [
            "import Flock",
            "",
            "Flock.configure(base: Base(), environments: [Production(), Staging()])",
            "",
            "Flock.use(.deploy)",
            "Flock.use(.swiftenv)",
            "Flock.use(.server)",
            "",
            "Flock.run()",
            ""
        ].joined(separator: "\n")
    }
    
    private func dependenciesDefault() -> String {
        return [
            "{",
            "   \"dependencies\" : [",
            "       {",
            "           \"url\" : \"https://github.com/jakeheis/Flock\",",
            "           \"major\": 0",
            "       }",
            "   ]",
            "}",
            ""
        ].joined(separator: "\n")
    }
    
    private func envConfigDefaults() -> [String] {
      return [
            "// Config.SSHAuthMethod = SSH.Key(",
            "//     privateKey: \"~/.ssh/key\",",
            "//     passphrase: \"passphrase\"",
            "// )",
            "// Flock.serve(ip: \"9.9.9.9\", user: \"user\", roles: [.app, .db, .web])"
      ]
    }
    
    private func baseDefaults() -> [String] {
        var projectName = "nil // Fill this in!"
        var executableName = "nil // // Fill this in! (same as Config.projectName unless your project is divided into modules)"
        var frameworkType = "GenericServer"
        do {
            let dump = try SPM.dump()

            guard let name = dump["name"] as? String else {
                throw SPM.Error.processFailed
            }
            projectName = "\"\(name)\""
            
            if let targets = dump["targets"] as? [[String: Any]], !targets.isEmpty {
                var targetNames = Set<String>()
                var dependencyNames = Set<String>()
                for target in targets {
                    guard let targetName = target["name"] as? String,
                        let dependencies = target["dependencies"] as? [String] else {
                            continue
                    }
                    targetNames.insert(targetName)
                    dependencyNames.formUnion(dependencies)
                }
                let executables = targetNames.subtracting(dependencyNames)
                if executables.count == 1 {
                    executableName = "\"\(executables.first!)\""
                }
            } else {
                executableName = projectName
            }
            
            if let dependencies = dump["dependencies"] as? [[String: Any]] {
                for dependency in dependencies {
                    guard let url = dependency["url"] as? String else {
                        continue
                    }
                    if url.hasPrefix("https://github.com/vapor/vapor") {
                        frameworkType = "Vapor"
                        break
                    } else if url.hasPrefix("https://github.com/Zewo/Zewo") {
                        frameworkType = "Zewo"
                        break
                    } else if url.hasPrefix("https://github.com/IBM-Swift/Kitura") {
                        frameworkType = "Kitura"
                        break
                    } else if url.hasPrefix("https://github.com/PerfectlySoft/Perfect") {
                        frameworkType = "Perfect"
                        break
                    }
                }
            }
        } catch {}
        
        
        
        var lines = [
            "Config.projectName = \(projectName)",
            "Config.executableName = \(executableName)",
            "Config.repoURL = nil // Fill this in!",
            "",
            "Config.serverFramework = \(frameworkType)Framework()",
            "Config.processController = Nohup() // Other option: Supervisord()",
            "",
            "// Optional config:",
            "// Config.deployDirectory = \"/var/www\"",
            "// Config.repoBranch = \"release\"",
        ]
        
        if !Path(".swift-version").exists {
            lines.append("// Config.swiftVersion = \"3.1\"")
        }
        
        return lines
    }
    
    private func packageDefault() -> String {
        return [
            "import PackageDescription",
            "",
            "// MARK: - You're free to change the `dependencies` array",
            "",
            "let dependencies: [Package.Dependency] = [",
            "    .Package(url: \"https://github.com/jakeheis/Flock\", majorVersion: 0)",
            "]",
            "",
            "// MARK: - Below is autogenerated, *do not modify*",
            "",
            "let package = Package(",
            "   name: \"Flockfile\",",
            "   dependencies: dependencies",
            ")",
            ""
        ].joined(separator: "\n")
    }
  
}
