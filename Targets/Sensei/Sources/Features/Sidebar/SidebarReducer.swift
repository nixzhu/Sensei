import SwiftUI
import ComposableArchitecture

struct SidebarReducer: ReducerProtocol {
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
    }

    var body: some ReducerProtocol<State, Action> {
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
            }
        }
    }
}

