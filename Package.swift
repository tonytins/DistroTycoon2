// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DistroTycoon",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "distrotycoon", targets: ["DistroTycoon"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/TermKit.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "DistroTycoon",
            dependencies: [.product(name: "TermKit", package: "TermKit")],
        ),
        .testTarget(
            name: "DistroTycoonTests",
            dependencies: ["DistroTycoon"],
        ),
    ],
    swiftLanguageModes: [.v6],
)
