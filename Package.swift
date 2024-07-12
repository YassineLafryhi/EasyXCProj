// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EasyXCProj",
    products: [
        .library(
            name: "EasyXCProj",
            targets: ["EasyXCProj"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "8.19.0")),
        ],
    targets: [
        .target(
            name: "EasyXCProj",
            dependencies: ["XcodeProj"]),
        .testTarget(
            name: "EasyXCProjTests",
            dependencies: ["EasyXCProj"]),
    ]
)
