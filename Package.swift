// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WiltCollector",
    products: [
        .executable(name: "WiltCollector", targets: ["WiltCollector"]),
        .library(name: "WiltCollectorCore", targets: ["WiltCollectorCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/oliveroneill/Soft.git", .branch("master")),
        .package(url: "https://github.com/oliveroneill/BigQuerySwift.git", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/saga-dash/auth-library-swift.git", .branch("master")),
    ],
    targets: [
        .target(name: "WiltCollector", dependencies: ["WiltCollectorCore"]),
        .target(name: "WiltCollectorCore", dependencies: ["Soft", "SwiftyRequest", "BigQuerySwift", "OAuth2"]),
        .testTarget(
            name: "WiltCollectorCoreTests",
            dependencies: ["WiltCollectorCore"]),
    ]
)
