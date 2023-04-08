import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppReducer>

    var body: some View {
        NavigationSplitView {
            SidebarView(
                store: store.scope(
                    state: \.sidebar,
                    action: { .sidebar($0) }
                )
            )
        } detail: {
            IfLetStore(
                store.scope(
                    state: \.detail,
                    action: { .detail($0) }
                )
            ) {
                DetailView(store: $0)
            } else: {
                Text("Select a chat or create a new one")
            }
        }
    }
}
