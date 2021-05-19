// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NNWCore",
    platforms: [.macOS(SupportedPlatform.MacOSVersion.v10_15), .iOS(SupportedPlatform.IOSVersion.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NNWCore",
            type: .dynamic,
            targets: ["NNWCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/Ranchero-Software/RSCore.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Ranchero-Software/RSDatabase.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Ranchero-Software/RSParser.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Ranchero-Software/RSWeb.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/OAuthSwift/OAuthSwift.git", .upToNextMajor(from: "2.1.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "NNWCore",
            dependencies: [
                "RSCore",
                "RSDatabase",
                "RSParser",
                "RSWeb",
                "OAuthSwift",
            ]),
        .testTarget(
            name: "NNWCoreTests",
            dependencies: ["NNWCore"],
            resources: [
                .copy("AccountTests/JSON"),
            ])
    ]
)
