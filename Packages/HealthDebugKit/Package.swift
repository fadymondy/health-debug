// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HealthDebugKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11)
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
