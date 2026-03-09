// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Features", targets: ["Features"])
    ],
    dependencies: [
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "Features",
            dependencies: ["Domain"],
            path: "Sources/Features"
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features"]
        )
    ]
)
