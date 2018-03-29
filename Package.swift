// swift-tools-version:4.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Flock",
    products: [
        .library(name: "Flock", targets: ["Flock"]),
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/jakeheis/Shout", from: "0.2.3"),
    ],
    targets: [
        .target(name: "Flock", dependencies: ["Rainbow", "Shout"]),
        .testTarget(name: "FlockTests", dependencies: ["Flock"]),
    ]
)
