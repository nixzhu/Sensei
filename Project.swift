import ProjectDescription

let name = "Sensei"

let project = Project(
    name: name,
    organizationName: "nixzhu",
    targets: [
        .init(
            name: name,
            platform: .macOS,
            product: .app,
            bundleId: "dev.nixzhu.\(name)",
            deploymentTarget: .macOS(targetVersion: "13.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "0.3.0",
                "CFBundleVersion": "9",
                "NSMainStoryboardFile": "",
                "UILaunchStoryboardName": "LaunchScreen",
                "NSHumanReadableCopyright": "Copyright @nixzhu. All rights reserved.",
            ]),
            sources: ["Targets/\(name)/Sources/**"],
            resources: ["Targets/\(name)/Resources/**"],
            dependencies: [
                .external(name: "Ananda"),
                .external(name: "ComposableArchitecture"),
                .external(name: "CustomDump"),
                .external(name: "Tagged"),
                .external(name: "IdentifiedCollections"),
                .external(name: "MarkdownUI"),
                .external(name: "GRDB"),
            ]
        ),
    ]
)
