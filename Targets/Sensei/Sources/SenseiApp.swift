import SwiftUI
import AppKit

@main
struct SenseiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
