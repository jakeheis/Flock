import PackageDescription

let package = Package(
  name: "Flock",
  dependencies: [
    .Package(url: "/Users/jakeheiser/Documents/Apps/SwiftCLI", majorVersion: 1, minor: 1),
    .Package(url: "/Users/jakeheiser/Documents/Swift/CNMSSH", majorVersion: 1, minor: 0)
  ]
)
