import SwiftUI
import AppKit

@main
struct SenseiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    var body: some Scene {
        WindowGroup {
            AppView(
                store: .init(
                    initialState: .init(
                        databaseManager: .shared
                    ),
                    reducer: AppReducer()
                )
            )
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    openWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(before: .help) {
                Button("Source Code") {
                    openURL(.init(string: "https://github.com/nixzhu/Sensei")!)
                }
                .keyboardShortcut("/", modifiers: .command)
            }
        }

        Window("Settings", id: "settings") {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
