// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Devpal",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Speech recognition, voice activity detection and speech: no text processing or diarization.
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.18.4", traits: ["TTS"]),
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
