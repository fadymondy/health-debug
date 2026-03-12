// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HealthDebugKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(
            name: "HealthDebugKit",
            targets: ["HealthDebugKit"]
        ),
    ],
    targets: [
        .target(
            name: "HealthDebugKit",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "HealthDebugKitTests",
            dependencies: ["HealthDebugKit"]
        ),
    ]
)
