// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Chip8",
    dependencies: [
        // .package(url: "https://github.com/apple/swift-testing.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Chip8",
            path: "Sources"
        ),
        .testTarget(
            name: "Chip8Tests",
            dependencies: [
                "Chip8",
                // .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests"
        )
    ]
)
