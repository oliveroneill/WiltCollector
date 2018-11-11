// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProrsumNet",
    products: [
        .library(
            name: "ProrsumNet",
            targets: ["ProrsumNet"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/clibressl.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "ProrsumNet",
            dependencies: ["CLibreSSL"]),
        .testTarget(
            name: "ProrsumNetTests",
            dependencies: ["ProrsumNet"]),
    ]
)
