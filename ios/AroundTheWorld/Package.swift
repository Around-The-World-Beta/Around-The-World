// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "AroundTheWorld",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "AroundTheWorldKit",
            targets: ["AroundTheWorldKit"]
        ),
    ],
    targets: [
        .target(
            name: "AroundTheWorldKit",
            path: "Sources/AroundTheWorldKit"
        ),
        .testTarget(
            name: "AroundTheWorldKitTests",
            dependencies: ["AroundTheWorldKit"],
            path: "Tests/AroundTheWorldKitTests"
        ),
    ]
)
