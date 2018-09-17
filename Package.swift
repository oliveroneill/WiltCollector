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
        .package(url: "https://github.com/swift-aws/dynamodb.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(name: "WiltCollector", dependencies: ["WiltCollectorCore"]),
        .target(name: "WiltCollectorCore", dependencies: ["Soft", "SwiftAWSDynamodb"]),
        .testTarget(
            name: "WiltCollectorCoreTests",
            dependencies: ["WiltCollectorCore"]),
    ]
)
