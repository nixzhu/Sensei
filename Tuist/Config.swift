import ProjectDescription

let config = Config(
    compatibleXcodeVersions: [.upToNextMajor("14.3")],
    swiftVersion: "5.8",
    generationOptions: .options(
        resolveDependenciesWithSystemScm: true,
        disablePackageVersionLocking: true
    )
)
