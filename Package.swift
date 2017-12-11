// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IronBank",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0"),
        .package(url: "https://github.com/webfrogs/HandOfTheKing.git", .branch("master")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "0.8.0")),
        // .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "0.5.0"),
        .package(url: "https://github.com/xcodeswift/xcproj.git", .upToNextMajor(from: "1.6.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "IronBank",
            dependencies: ["IronBankKit"]),
        .target(
            name: "IronBankKit",
            dependencies: ["Rainbow", "HandOfTheKing", "CryptoSwift", "Yams", "xcproj"]),
    ]
)
