// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iceNotePad",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "iceNotePad",
            targets: ["iceNotePad"]
        )
    ],
    targets: [
        .executableTarget(
            name: "iceNotePad",
            path: "Sources/iceNotePad"
        ),
        .testTarget(
            name: "iceNotePadTests",
            dependencies: ["iceNotePad"],
            path: "Tests/iceNotePadTests"
        )
    ]
)

