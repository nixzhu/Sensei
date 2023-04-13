import SwiftUI
import ComposableArchitecture

struct AppReducer: Reducer {
    @Dependency(\.databaseManager) var databaseManager

    struct State: Equatable {
        var settings: SettingsReducer.State
        var chats: IdentifiedArrayOf<Chat>
        var currentChatID: Chat.ID?
        var chatMessages: [Chat.ID: IdentifiedArrayOf<Message>]
        var messageIDToScrollTo: Message.ID?
        var input: String
        var isNewChatPresented: Bool
        var isEditChatPresented: Bool
        var isTextModeEnabled: Bool
        var isFileExporterPresented: Bool
        var sidebarAlert: AlertState<SidebarReducer.Action>?
        var detailAlert: AlertState<DetailReducer.Action>?

        var currentChat: Chat? {
            currentChatID.flatMap { chats[id: $0] }
        }

        var sidebar: SidebarReducer.State {
            get {
                .init(
                    chats: chats,
                    currentChat: currentChat,
                    isNewChatPresented: isNewChatPresented,
                    alert: sidebarAlert
                )
            }
            set {
                chats = newValue.chats
                currentChatID = newValue.currentChat?.id
                isNewChatPresented = newValue.isNewChatPresented
                sidebarAlert = newValue.alert
            }
        }

        var detail: DetailReducer.State? {
            get {
                if let chat = currentChat {
                    return .init(
                        chat: chat,
                        messages: chatMessages[chat.id] ?? [],
                        messageIDToScrollTo: messageIDToScrollTo,
                        enterToSend: settings.enterToSend,
                        input: input,
                        isEditChatPresented: isEditChatPresented,
                        isTextModeEnabled: isTextModeEnabled,
                        isFileExporterPresented: isFileExporterPresented,
                        alert: detailAlert
                    )
                }

                return nil
            }
            set {
                if let newValue {
                    let chat = newValue.chat
                    chats[id: chat.id] = chat
                    chatMessages[chat.id] = newValue.messages
                    messageIDToScrollTo = newValue.messageIDToScrollTo
                    settings.enterToSend = newValue.enterToSend
                    input = newValue.input
                    isEditChatPresented = newValue.isEditChatPresented
                    isTextModeEnabled = newValue.isTextModeEnabled
                    isFileExporterPresented = newValue.isFileExporterPresented
                    detailAlert = newValue.alert
                }
            }
        }

        init(databaseManager: DatabaseManager) {
            settings = .init(
                customHost: Settings.customHost,
                apiKey: Settings.apiKey,
                enterToSend: Settings.enterToSend
            )

            do {
                let localChats = try databaseManager.chats()

                chats = .init(
                    uniqueElements: localChats
                        .map { $0.chat }
                        .sorted(by: { $0.updatedAt > $1.updatedAt })
                )

                currentChatID = chats.first?.id
            } catch {
                chats = []
                currentChatID = nil
            }

            chatMessages = [:]
            input = ""
            isNewChatPresented = false
            isEditChatPresented = false
            isTextModeEnabled = false
            isFileExporterPresented = false
            sidebarAlert = nil
            detailAlert = nil
        }
    }

    enum Action: Equatable {
        case settings(SettingsReducer.Action)
        case sidebar(SidebarReducer.Action)
        case detail(DetailReducer.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.settings, action: /Action.settings) {
            SettingsReducer()
        }

        Scope(state: \.sidebar, action: /Action.sidebar) {
            SidebarReducer()
        }
        .ifLet(\.detail, action: /Action.detail) {
            DetailReducer()
        }

        Reduce { state, action in
            switch action {
            case .settings(let action):
                switch action {
                case .updateCustomHost(let customHost):
                    Settings.customHost = customHost
                case .updateAPIKey(let apiKey):
                    Settings.apiKey = apiKey
                case .updateEnterToSend(let enterToSend):
                    Settings.enterToSend = enterToSend
                }
            case .sidebar(let action):
                switch action {
                case .selectChat(let chat):
                    if let chat {
                        do {
                            let localMessages = try databaseManager.messages(of: chat.localChat)

                            state.chatMessages[chat.id] = .init(
                                uniqueElements: localMessages.map { $0.message }
                            )

                            state.messageIDToScrollTo = nil
                        } catch {
                            print("error:", error)
                        }
                    }
                case .deleteChat(let chat):
                    state.chatMessages[chat.id] = nil

                    if let chat = state.currentChat {
                        do {
                            let localMessages = try databaseManager.messages(of: chat.localChat)

                            state.chatMessages[chat.id] = .init(
                                uniqueElements: localMessages.map { $0.message }
                            )
                        } catch {
                            print("error:", error)
                        }
                    }
                default:
                    break
                }
            case .detail(let action):
                switch action {
                case .updateChat:
                    state.chats.sort(by: { $0.updatedAt > $1.updatedAt })
                case .appendMessage(let message):
                    if var chat = state.chats[id: message.chatID] {
                        chat.updatedAt = .init()

                        do {
                            try databaseManager.update(chat.localChat)
                            state.chats[id: chat.id] = chat
                            state.chats.sort(by: { $0.updatedAt > $1.updatedAt })
                        } catch {
                            print("error:", error)
                        }
                    }
                default:
                    break
                }
            }

            return .none
        }
    }
}
