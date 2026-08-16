// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RepoFeed",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "RepoFeed", targets: ["RepoFeed"])
    ],
    targets: [
        .executableTarget(name: "RepoFeed"),
        .testTarget(name: "RepoFeedTests", dependencies: ["RepoFeed"])
    ]
)
