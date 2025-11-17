// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SVGAssetConverter",
  defaultLocalization: "en",
  platforms: [.iOS(.v18), .macOS(.v15), .macCatalyst(.v18), .watchOS(.v11), .visionOS(.v2)],
  dependencies: [
    .package(
      url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git",
      .upToNextMajor(from: "6.2.0")
    ),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "SVGAssetConverter",
      dependencies: [
        .product(
          name: "SFSafeSymbols",
          package: "SFSafeSymbols"
        ),
      ],
      resources: [
        .process("Resources/"),
      ]
    ),
  ]
)
