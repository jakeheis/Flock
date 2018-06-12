// swift-tools-version:4.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Flock",
    products: [
        .executable(name: "flock", targets: ["FlockCLI"]),
        .library(name: "FlockKit", targets: ["FlockKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/yonaskolb/Beak", from: "0.4.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/jakeheis/Shout", from: "0.2.3"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.1.1"),
    ],
    targets: [
        .target(name: "FlockCLI", dependencies: ["BeakCore", "Rainbow", "SwiftCLI"]),
        .target(name: "FlockKit", dependencies: ["Rainbow", "Shout"]),
    ]
)
