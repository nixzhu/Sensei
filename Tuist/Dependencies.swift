import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .remote(
            url: "https://github.com/nixzhu/Ananda.git",
            requirement: .upToNextMajor(from: "0.1.1")
        ),
        .remote(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            requirement: .branch("prerelease/1.0")
        ),
        .remote(
            url: "https://github.com/pointfreeco/swift-custom-dump.git",
            requirement: .upToNextMajor(from: "0.10.0")
        ),
        .remote(
            url: "https://github.com/pointfreeco/swift-tagged.git",
            requirement: .upToNextMajor(from: "0.10.0")
        ),
        .remote(
            url: "https://github.com/gonzalezreal/swift-markdown-ui.git",
            requirement: .branch("main")
        ),
        .remote(
            url: "https://github.com/groue/GRDB.swift.git",
            requirement: .upToNextMajor(from: "6.10.1")
        ),
    ],
    platforms: [.macOS]
)
