import PackageDescription

let package = Package(
    name: "Flock",
    dependencies: [
        .Package(url: "https://github.com/jakeheis/SwiftCLI", majorVersion: 1, minor: 2),
        .Package(url: "https://github.com/onevcat/Rainbow", majorVersion: 1)
    ]
)
