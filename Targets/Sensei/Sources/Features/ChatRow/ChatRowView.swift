import SwiftUI
import ComposableArchitecture

struct ChatRowView: View {
    let store: StoreOf<ChatRowReducer>
    @State private var over = false

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            HStack(spacing: 0) {
                Text(
                    viewStore.state.name
                )

                Spacer()

                Button {
                    viewStore.send(.tryDeleteChat)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete")
                .opacity(over ? 1 : 0)
            }
            .onHover {
                over = $0
            }
            .tag(viewStore.state)
        }
    }
}

struct ChatRowView_Previews: PreviewProvider {
    static var previews: some View {
        ChatRowView(
            store: .init(
                initialState: .init(
                    id: .init(1),
                    name: "闲聊",
                    model: .gpt_3_5_turbo,
                    prompt: "语言简洁易懂的博士",
                    temperature: 0.3,
                    numberOfMessagesInContext: 4,
                    updatedAt: .distantPast
                ),
                reducer: ChatRowReducer()
            )
        )
    }
}
