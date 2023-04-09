import SwiftUI
import ComposableArchitecture

struct DetailReducer: ReducerProtocol {
    @Dependency(\.databaseManager) var databaseManager

    struct State: Equatable {
        var chat: Chat
        var messages: IdentifiedArrayOf<Message>
        var input: String
        var isEditChatPresented: Bool
        var isTextModeEnabled: Bool
        var isFileExporterPresented: Bool
        var alert: AlertState<Action>?

        var chatContent: String {
            messages.compactMap { (message: Message) -> String? in
                switch message.source {
                case .me:
                    return "## \(message.content)"
                case .sensei:
                    return message.content
                case .error:
                    return nil
                case .breaker:
                    return "---"
                case .receiving:
                    return nil
                }
            }
            .joined(separator: "\n\n")
        }
    }

    enum Action: Equatable {
        case tryClearAllMessages
        case clearAllMessages
        case clearErrorMessages
        case clearToMessage(Message)
        case updateInput(String)
        case sendInputIfCan(ScrollViewProxy)
        case retryChatIfCan(ScrollViewProxy)
        case appendMessage(Message, ScrollViewProxy)
        case updateMessage(Message, ScrollViewProxy)
        case scrollToMessage(Message, ScrollViewProxy)
        case markReceiving(ScrollViewProxy)
        case sendChatIfCan(ScrollViewProxy)
        case clearReceivingMessages
        case updateEditChatPresented(Bool)
        case updateChat(Chat)
        case toggleTextModeEnabled
        case updateFileExporterPresented(Bool)
        case breakChat(ScrollViewProxy)
        case dismissAlert
    }

    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .tryClearAllMessages:
                state.alert = .init(
                    title: { .init("Clear all messages?") },
                    actions: {
                        ButtonState<Action>.cancel(.init("Cancel"))

                        ButtonState<Action>.destructive(
                            .init("Clear"),
                            action: .send(.clearAllMessages)
                        )
                    }
                )

                return .none
            case .clearAllMessages:
                do {
                    try databaseManager.clearMessages(of: state.chat.localChat)
                    state.messages = []
                } catch {
                    print("error:", error)
                }

                return .none
            case .clearErrorMessages:
                do {
                    try databaseManager.clearErrorMessages(of: state.chat.localChat)
                    state.messages.removeAll(where: { $0.source == .error })
                } catch {
                    print("error:", error)
                }

                return .none
            case .clearToMessage(let targetMessage):
                let lastMessages: [Message] = {
                    var messages: [Message] = []

                    for message in state.messages.reversed() {
                        messages.append(message)

                        if message.id == targetMessage.id {
                            break
                        }
                    }

                    return messages
                }()

                do {
                    try databaseManager.deleteMessages(lastMessages.compactMap { $0.localMessage })
                    state.messages.removeLast(lastMessages.count)
                } catch {
                    print("error:", error)
                }

                return .none
            case .updateInput(let newInput):
                state.input = newInput
                return .none
            case .sendInputIfCan(let scrollViewProxy):
                guard !state.messages.contains(where: { $0.source == .receiving }) else {
                    return .none
                }

                let fixedInput = state.input.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                guard !fixedInput.isEmpty else { return .none }

                do {
                    let localMessage = try databaseManager.insert(
                        LocalMessage(
                            chatID: state.chat.id.rawValue,
                            source: .me,
                            content: fixedInput
                        )
                    )

                    let message = localMessage.message

                    return .run { send in
                        await send(.updateInput(""))
                        await send(.appendMessage(message, scrollViewProxy))
                        await send(.markReceiving(scrollViewProxy))
                        await send(.sendChatIfCan(scrollViewProxy))
                    }
                } catch {
                    print("error:", error)
                    return .none
                }
            case .retryChatIfCan(let scrollViewProxy):
                guard !state.messages.isEmpty else { return .none }

                return .run { send in
                    await send(.clearErrorMessages)
                    await send(.markReceiving(scrollViewProxy))
                    await send(.sendChatIfCan(scrollViewProxy))
                }
            case .appendMessage(let message, let scrollViewProxy):
                if message.chatID == state.chat.id {
                    state.messages.append(message)

                    return .send(
                        .scrollToMessage(message, scrollViewProxy)
                    )
                } else {
                    return .none
                }
            case .updateMessage(let message, let scrollViewProxy):
                if message.chatID == state.chat.id {
                    state.messages[id: message.id] = message

                    return .send(
                        .scrollToMessage(message, scrollViewProxy)
                    )
                } else {
                    return .none
                }
            case .scrollToMessage(let message, let scrollViewProxy):
                return .run { _ in
                    withAnimation {
                        scrollViewProxy.scrollTo(message.id, anchor: .bottom)
                    }

                    try await Task.sleep(seconds: 0.1)
                }
            case .markReceiving(let scrollViewProxy):
                let message = Message(
                    id: .init("receiving"),
                    chatID: state.chat.id,
                    source: .receiving,
                    content: ""
                )

                return .send(
                    .appendMessage(message, scrollViewProxy)
                )
            case .sendChatIfCan(let scrollViewProxy):
                let chat = state.chat

                let latestPartMessages: [Message] = {
                    var validMessages: [Message] = []

                    for message in state.messages.reversed() {
                        if message.source == .breaker {
                            break
                        } else {
                            validMessages.append(message)
                        }
                    }

                    return validMessages.reversed()
                }()

                let messages: [API.Message] = latestPartMessages
                    .filter { $0.source == .me || $0.source == .sensei }
                    .suffix(chat.numberOfMessagesInContext + 1)
                    .compactMap {
                        switch $0.source {
                        case .me:
                            return .init(role: .user, content: $0.content)
                        case .sensei:
                            return .init(role: .assistant, content: $0.content)
                        case .error:
                            return nil
                        case .breaker:
                            return nil
                        case .receiving:
                            return nil
                        }
                    }

                guard !messages.isEmpty else { return .none }

                return .run { send in
                    do {
                        let stream = try await API.chatCompletions(
                            model: chat.model,
                            temperature: chat.temperature,
                            messages: [.init(role: .system, content: chat.prompt)] + messages
                        )

                        var receivingLocalMessage: LocalMessage?

                        for try await text in stream {
                            if var localMessage = receivingLocalMessage {
                                localMessage.content += text

                                try databaseManager.update(localMessage)

                                receivingLocalMessage = localMessage

                                await send(.updateMessage(localMessage.message, scrollViewProxy))
                            } else {
                                let localMessage = try databaseManager.insert(
                                    LocalMessage(
                                        chatID: chat.id.rawValue,
                                        source: .sensei,
                                        content: text
                                    )
                                )

                                receivingLocalMessage = localMessage

                                await send(.clearReceivingMessages)
                                await send(.appendMessage(localMessage.message, scrollViewProxy))
                            }
                        }
                    } catch {
                        let localMessage = try databaseManager.insert(
                            LocalMessage(
                                chatID: chat.id.rawValue,
                                source: .error,
                                content: error.localizedDescription
                            )
                        )

                        let message = localMessage.message

                        await send(.clearReceivingMessages)
                        await send(.appendMessage(message, scrollViewProxy))
                    }
                }
            case .clearReceivingMessages:
                state.messages.removeAll(where: { $0.source == .receiving })
                return .none
            case .updateEditChatPresented(let isPresented):
                state.isEditChatPresented = isPresented
                return .none
            case .updateChat(let chat):
                do {
                    try databaseManager.update(chat.localChat)
                    state.chat = chat
                } catch {
                    print("error:", error)
                }

                return .none
            case .toggleTextModeEnabled:
                state.isTextModeEnabled.toggle()
                return .none
            case .updateFileExporterPresented(let isPresented):
                state.isFileExporterPresented = isPresented
                return .none
            case .breakChat(let scrollViewProxy):
                do {
                    let localMessage = try databaseManager.insert(
                        LocalMessage(
                            chatID: state.chat.id.rawValue,
                            source: .breaker,
                            content: ""
                        )
                    )

                    let message = localMessage.message

                    return .send(
                        .appendMessage(message, scrollViewProxy)
                    )
                } catch {
                    print("error:", error)
                    return .none
                }
            case .dismissAlert:
                state.alert = nil
                return .none
            }
        }
    }
}
