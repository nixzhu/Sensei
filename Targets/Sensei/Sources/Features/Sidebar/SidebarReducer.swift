import SwiftUI
import ComposableArchitecture

struct SidebarReducer: Reducer {
    @Dependency(\.databaseManager) var databaseManager

    struct State: Equatable {
        var chats: IdentifiedArrayOf<Chat>
        var currentChat: Chat?
        var isNewChatPresented: Bool
        var alert: AlertState<Action>?
    }

    enum Action: Equatable {
        case selectChat(Chat?)
        case tryDeleteChat(Chat)
        case deleteChat(Chat)
        case updateNewChatPresented(Bool)
        case createNewChat(LocalChat)
        case dismissAlert
        case chatRow(id: ChatRowReducer.State.ID, action: ChatRowReducer.Action)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .selectChat(let chat):
                state.currentChat = chat
                return .none
            case .tryDeleteChat(let chat):
                state.alert = .init(
                    title: { .init("Delete \(chat.name)?") },
                    actions: {
                        ButtonState<Action>.cancel(.init("Cancel"))

                        ButtonState<Action>.destructive(
                            .init("Delete"),
                            action: .send(.deleteChat(chat))
                        )
                    }
                )

                return .none
            case .deleteChat(let chat):
                do {
                    try databaseManager.delete(chat.localChat)
                    state.chats.remove(id: chat.id)
                    state.currentChat = state.chats.first
                } catch {
                    print("error:", error)
                }

                return .none
            case .updateNewChatPresented(let isPresented):
                state.isNewChatPresented = isPresented
                return .none
            case .createNewChat(let localChat):
                do {
                    let localChat = try databaseManager.insert(localChat)
                    let chat = localChat.chat
                    state.chats.insert(chat, at: 0)
                    state.currentChat = chat
                } catch {
                    print("error:", error)
                }

                return .none
            case .dismissAlert:
                state.alert = nil
                return .none
            case .chatRow(let id, let action):
                if let chat = state.chats[id: id] {
                    switch action {
                    case .tryDeleteChat:
                        state.alert = .init(
                            title: { .init("Delete \(chat.name)?") },
                            actions: {
                                ButtonState<Action>.cancel(.init("Cancel"))

                                ButtonState<Action>.destructive(
                                    .init("Delete"),
                                    action: .send(.deleteChat(chat))
                                )
                            }
                        )
                    }
                }

                return .none
            }
        }
        .forEach(\.chats, action: /Action.chatRow) {
            ChatRowReducer()
        }
    }
}

