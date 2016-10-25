import Foundation

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
        return "\(currentDirectory)/.build/debug/\(Config.executableName)"
    }
    
}
