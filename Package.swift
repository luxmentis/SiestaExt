// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SiestaExt",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SiestaExt",
            targets: ["SiestaExt"]),
    ],
    dependencies: [
        .package(url: "https://github.com/bustoutsolutions/siesta", .upToNextMajor(from: "1.5.2")),
        .package(url: "https://github.com/CombineCommunity/CombineExt", .upToNextMajor(from: "1.8.1")),

        // For tests:
        .package(url: "https://github.com/pcantrell/Quick", branch: "siesta"),
        .package(url: "https://github.com/Quick/Nimble", from: "9.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SiestaExt", dependencies: [
            .product(name: "Siesta", package: "Siesta"),
            .product(name: "CombineExt", package: "CombineExt"),
        ]),

        .testTarget(
            name: "SiestaExtTests",
            dependencies: ["SiestaExt", "Quick", "Nimble"]
        ),
    ]
)
