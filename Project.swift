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
            bundleId: {
                let bundleIDPrefix = Environment.bundleIDPrefix.getString(default: "")

                if bundleIDPrefix.isEmpty {
                    return "io.tuist.\(name)"
                } else {
                    return "\(bundleIDPrefix).\(name)"
                }
            }(),
            deploymentTarget: .macOS(targetVersion: "13.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": .string(
                    {
                        let string = Environment.version.getString(default: "")

                        if string.isEmpty {
                            return "0.3.0"
                        } else {
                            return string
                        }
                    }()
                ),
                "CFBundleVersion": .string(
                    {
                        let string = Environment.build.getString(default: "")

                        if string.isEmpty {
                            return "9"
                        } else {
                            return string
                        }
                    }()
                ),
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
                .external(name: "MarkdownUI"),
                .external(name: "GRDB"),
            ],
            settings: .settings(
                base: {
                    SettingsDictionary()
                        .strictConcurrencyChecking(.complete)
                }(),
                defaultSettings: .recommended
            )
        ),
    ]
)

extension Dictionary where Key == String, Value == SettingValue {
    enum StrictConcurrencyChecking: String {
        case minimal
        case targeted
        case complete
    }

    func strictConcurrencyChecking(_ value: StrictConcurrencyChecking) -> SettingsDictionary {
        var info = self
        info["SWIFT_STRICT_CONCURRENCY"] = .string(value.rawValue)

        return info
    }
}
