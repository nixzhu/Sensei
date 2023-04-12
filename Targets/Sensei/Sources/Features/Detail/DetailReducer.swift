import SwiftUI
import ComposableArchitecture

struct DetailReducer: Reducer {
    @Dependency(\.databaseManager) var databaseManager
    @Dependency(\.continuousClock) var clock

    struct State: Equatable {
        var chat: Chat
        var messages: IdentifiedArrayOf<Message>
        var messageIDToScrollTo: Message.ID?
        var enterToSend: Bool
        var input: String
        var isEditChatPresented: Bool
        var isTextModeEnabled: Bool
        var isFileExporterPresented: Bool
        var alert: AlertState<Action>?

        var chatContent: String {
            messages.compactMap {
                switch $0.source {
                case .me:
                    return "## \($0.content)"
                case .sensei:
                    return $0.content
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
        case updateInput(String)
        case sendInputIfCan
        case appendMessage(Message)
        case updateMessage(Message)
        case replaceReceivingMessageWithNewMessage(Message)
        case scrollToMessage(Message)
        case markReceiving
        case sendChatIfCan
        case updateEditChatPresented(Bool)
        case updateChat(Chat)
        case toggleTextModeEnabled
        case updateFileExporterPresented(Bool)
        case breakChat
        case dismissAlert
        case messageRow(id: MessageRowReducer.State.ID, action: MessageRowReducer.Action)
    }

    var body: some Reducer<State, Action> {
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
            case .updateInput(let newInput):
                state.input = newInput
                state.messageIDToScrollTo = state.messages.last?.id
                return .none
            case .sendInputIfCan:
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
                        await send(.appendMessage(message))
                        await send(.markReceiving)
                        await send(.sendChatIfCan)
                    }
                } catch {
                    print("error:", error)
                    return .none
                }
            case .appendMessage(let message):
                if message.chatID == state.chat.id {
                    state.messages.append(message)

                    return .send(
                        .scrollToMessage(message)
                    )
                } else {
                    return .none
                }
            case .updateMessage(let message):
                if message.chatID == state.chat.id {
                    state.messages[id: message.id] = message

                    return .send(
                        .scrollToMessage(message)
                    )
                } else {
                    return .none
                }
            case .replaceReceivingMessageWithNewMessage(let message):
                if message.chatID == state.chat.id {
                    state.messages.removeAll(where: { $0.source == .receiving })
                    state.messages.append(message)

                    return .send(
                        .scrollToMessage(message)
                    )
                } else {
                    return .none
                }
            case .scrollToMessage(let message):
                if message.chatID == state.chat.id {
                    state.messageIDToScrollTo = message.id
                }

                return .none
            case .markReceiving:
                let message = Message(
                    id: .init("receiving"),
                    chatID: state.chat.id,
                    source: .receiving,
                    content: ""
                )

                return .send(
                    .appendMessage(message)
                )
            case .sendChatIfCan:
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

                                await send(.updateMessage(localMessage.message))
                            } else {
                                let localMessage = try databaseManager.insert(
                                    LocalMessage(
                                        chatID: chat.id.rawValue,
                                        source: .sensei,
                                        content: text
                                    )
                                )

                                receivingLocalMessage = localMessage

                                await send(
                                    .replaceReceivingMessageWithNewMessage(
                                        localMessage.message
                                    )
                                )
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

                        await send(
                            .replaceReceivingMessageWithNewMessage(
                                localMessage.message
                            )
                        )
                    }
                }
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
            case .breakChat:
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
                        .appendMessage(message)
                    )
                } catch {
                    print("error:", error)
                    return .none
                }
            case .dismissAlert:
                state.alert = nil
                return .none
            case .messageRow(let id, let action):
                switch action {
                case .clearFromBottomToThisMessage:
                    if let targetMessage = state.messages[id: id] {
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
                            try databaseManager.deleteMessages(
                                lastMessages.compactMap { $0.localMessage }
                            )

                            state.messages.removeLast(lastMessages.count)
                        } catch {
                            print("error:", error)
                        }
                    }

                    return .none
                case .retryChatIfCan:
                    guard !state.messages.isEmpty else { return .none }

                    return .run { send in
                        await send(.clearErrorMessages)
                        await send(.markReceiving)
                        await send(.sendChatIfCan)
                    }
                case .copyMessage:
                    return .none
                }
            }
        }
        .forEach(\.messages, action: /Action.messageRow) {
            MessageRowReducer()
        }
    }
}
