// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DistroTycoon",
    products: [
        .executable(name: "distrotycoon", targets: ["DistroTycoon"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tonytins/raylib-swift", branch: "main"),
        .package(url: "https://github.com/tonytins/Hudini.git", branch: "main"),
        .package(url: "https://github.com/tonytins/GitVersion.git", from: "0.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "DistroTycoon",
            dependencies: [
                .product(name: "Raylib", package: "raylib-swift"),
                .product(name: "Hudini", package: "Hudini"),
                .product(name: "GitVersion", package: "GitVersion"),
            ],
            plugins: [
                .plugin(name: "GitVersionPlugin", package: "GitVersion"),
            ],
        ),
        .testTarget(
            name: "DistroTycoonTests",
            dependencies: ["DistroTycoon"],
        ),
    ],
    swiftLanguageModes: [.v6],
)
