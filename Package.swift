// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoogleTokenProvider",
    products: [
        .library(
            name: "GoogleTokenProvider",
            targets: ["GoogleTokenProvider"]),
    ],
    dependencies: [
        .package(url: "https://github.com/alexfilimon/SwiftConnection", from: "1.0.3"),
        .package(url: "https://github.com/kylef/PathKit.git", from: "0.9.1"),
        .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.4.7")),
    ],
    targets: [
        .target(
            name: "GoogleTokenProvider",
            dependencies: ["SwiftConnection", "PathKit", "Swifter"]),
        .testTarget(
            name: "GoogleTokenProviderTests",
            dependencies: ["GoogleTokenProvider"]),
    ]
)
