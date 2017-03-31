import PackageDescription

let package = Package(
    name: "Flock",
    dependencies: [
        .Package(url: "https://github.com/jakeheis/SwiftCLI", Version("3.0.0-beta3")),
        .Package(url: "https://github.com/onevcat/Rainbow", majorVersion: 2, minor: 0),
        .Package(url: "https://github.com/jakeheis/Spawn", majorVersion: 0, minor: 0)
    ]
)
