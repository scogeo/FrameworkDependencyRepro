// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "shared-models",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "SharedModels",
      targets: ["SharedModels"]
    ),
    .library(
      name: "WidgetSync",
      targets: ["WidgetSync"]
    ),
  ],
  dependencies: [
//    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.0"),
    .package(url: "https://github.com/scogeo/swift-dependencies", branch: "experiment"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "SharedModels",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ]
    ),
    .testTarget(
      name: "SharedModelsTests",
      dependencies: [
        "SharedModels"
      ]
    ),
    .target(
      name: "WidgetSync",
      dependencies: [
        "SharedModels",
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
