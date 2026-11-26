// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Devpal",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Devpal",
            path: "Sources/Devpal",
            resources: [.copy("Shaders")]
        ),
    ]
)
