// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swift-nio-ssh",
    products: [
        .library(name: "NIOSSH", targets: ["NIOSSH"]),
        .executable(name: "NIOSSHClient", targets: ["NIOSSHClient"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "NIOSSH",
            dependencies: ["NIO"]),
        .target(
            name: "NIOSSHClient",
            dependencies: ["NIOSSH"]),
        .testTarget(
            name: "NIOSSHTests",
            dependencies: ["NIOSSH"]),
    ]
)
