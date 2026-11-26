// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Devpal",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Speech recognition and voice activity detection only: no text processing, speech or diarization.
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.18.4", traits: []),
    ],
    targets: [
        .executableTarget(
            name: "Devpal",
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")],
            path: "Sources/Devpal",
            resources: [.copy("Shaders")]
        ),
    ]
)
