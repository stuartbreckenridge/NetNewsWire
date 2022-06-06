// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SyncDatabase",
	platforms: [.macOS(SupportedPlatform.MacOSVersion.v10_15), .iOS(SupportedPlatform.IOSVersion.v13)],
    products: [
        .library(
            name: "SyncDatabase",
			type: .dynamic,
            targets: ["SyncDatabase"]),
    ],
    dependencies: [
		.package(url: "https://github.com/Ranchero-Software/RSCore.git", .upToNextMajor(from: "1.0.0")),
		.package(url: "https://github.com/Ranchero-Software/RSDatabase.git", .upToNextMajor(from: "1.0.0")),
		.package(path: "../Articles"),
    ],
    targets: [
        .target(
            name: "SyncDatabase",
            dependencies: [
				"RSCore",
				"RSDatabase",
				"Articles",
			]),
    ]
)
