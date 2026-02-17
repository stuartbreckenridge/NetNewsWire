// swift-tools-version:6.2
import PackageDescription

let package = Package(
	name: "Localizations",
	platforms: [.macOS(.v26), .iOS(.v26)],
	products: [
		.library(
			name: "Localizations",
			type: .dynamic,
			targets: ["Localizations"])
	],
	targets: [
		.target(
			name: "Localizations",
			resources: [
				.process("Resources")
			],
			swiftSettings: [
				.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
				.enableUpcomingFeature("InferIsolatedConformances")
			]
		)
	]
)
