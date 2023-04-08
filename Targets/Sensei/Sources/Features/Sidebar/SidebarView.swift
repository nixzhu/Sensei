import SwiftUI
import ComposableArchitecture

struct SidebarView: View {
    let store: StoreOf<SidebarReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List(
                viewStore.chats,
                selection: viewStore.binding(
                    get: \.currentChat,
                    send: { .selectChat($0) }
                )
            ) { chat in
                Text(
                    chat.name
                )
                .tag(chat)
                .contextMenu {
                    Button {
                        viewStore.send(.tryDeleteChat(chat))
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 300)
            .toolbar {
                ToolbarItemGroup {
                    Spacer()

                    Button {
                        viewStore.send(.updateNewChatPresented(true))
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("New chat")
                    .sheet(
                        isPresented: viewStore.binding(
                            get: \.isNewChatPresented,
                            send: { .updateNewChatPresented($0) }
                        )
                    ) {
                        NewChatView(
                            cancelAction: {
                                viewStore.send(.updateNewChatPresented(false))
                            },
                            doneAction: { localChat in
                                viewStore.send(.createNewChat(localChat))
                                viewStore.send(.updateNewChatPresented(false))
                            }
                        )
                    }
                }
            }
            .alert(
                store.scope(state: \.alert),
                dismiss: .dismissAlert
            )
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationSplitView {
            SidebarView(
                store: .init(
                    initialState: SidebarReducer.State(
                        chats: [
                            .init(
                                id: .init(1),
                                name: "闲聊",
                                model: .gpt_3_5_turbo,
                                prompt: "语言简洁易懂的博士",
                                temperature: 0.3,
                                numberOfMessagesInContext: 4,
                                updatedAt: .init()
                            ),
                        ],
                        currentChat: nil,
                        isNewChatPresented: false
                    ),
                    reducer: SidebarReducer()
                )
            )
            .frame(width: 200)
        } detail: {
            Text("Detail")
        }
        .frame(width: 400)
    }
}
