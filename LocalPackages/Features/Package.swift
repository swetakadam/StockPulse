// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "Features", targets: ["Features"])
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(url: "https://github.com/hmlongco/Factory", from: "2.3.0")
    ],
    targets: [
        .target(
            name: "Features",
            dependencies: ["Domain", "Factory"],
            path: "Sources/Features"
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features"],
            path: "Tests/FeaturesTests"
        )
    ]
)
