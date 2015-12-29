import PackageDescription

let package = Package(
  name: "Flock",
  dependencies: [
    .Package(url: "https://github.com/jakeheis/SwiftCLI.git", majorVersion: 1, minor: 1)
  ]
)
