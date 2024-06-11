// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SiestaExt",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
    ],
    products: [
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
        .target(
            name: "SiestaExt",
            dependencies: [
                .product(name: "Siesta", package: "Siesta"),
                .product(name: "CombineExt", package: "CombineExt"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        .testTarget(
            name: "SiestaExtTests",
            dependencies: ["SiestaExt", "Quick", "Nimble"]
        ),
    ]
)
