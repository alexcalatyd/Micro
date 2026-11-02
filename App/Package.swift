// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MiniPlayerApp",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "MiniPlayerApp",
            path: "Sources/MiniPlayerApp"
        )
    ]
)
