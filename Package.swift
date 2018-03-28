// swift-tools-version:4.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Flock",
    products: [
        .executable(name: "flock", targets: ["FlockCLI"]),
        .library(name: "FlockLib", targets: ["FlockLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit", from: "0.8.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/jakeheis/Shout", from: "0.2.3"),
        .package(url: "https://github.com/jakeheis/Spawn", from: "0.0.6"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "4.1.0"),
    ],
    targets: [
        .target(name: "FlockCLI", dependencies: ["PathKit", "Rainbow", "Spawn", "SwiftCLI"]),
        .target(name: "FlockLib", dependencies: ["Rainbow", "Shout", "Spawn"]),
        .testTarget(name: "FlockLibTests", dependencies: ["FlockLib"]),
    ]
)
