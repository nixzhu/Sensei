import SwiftUI
import ComposableArchitecture

struct DetailView: View {
    private enum FocusedField {
        case input
    }

    let store: StoreOf<DetailReducer>

    @FocusState private var focusedField: FocusedField?

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    ZStack {
                        Color.clear

                        VStack {
                            ForEachStore(
                                store.scope(
                                    state: \.messages,
                                    action: DetailReducer.Action.messageRow(id:action:)
                                )
                            ) {
                                MessageRowView(store: $0)
                                    .rotationEffect(.radians(.pi))
                                    .scaleEffect(x: -1, y: 1, anchor: .center)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                .background(Color(.textBackgroundColor))
                .onChange(of: viewStore.animatedMessageToScrollTo) { value in
                    if let value {
                        if value.animated {
                            withAnimation {
                                scrollViewProxy.scrollTo(value.message.id, anchor: value.anchor)
                            }
                        } else {
                            scrollViewProxy.scrollTo(value.message.id, anchor: value.anchor)
                        }

                        viewStore.send(.resetAnimatedMessageToScrollTo)
                    }
                }
                .overlay {
                    if viewStore.messages.isEmpty {
                        VStack {
                            Text("🤖")
                                .font(.system(size: 48))

                            Text("How can I help you?")
                                .bold()
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if !viewStore.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(
                            { () -> AttributedString in
                                if viewStore.enterToSend {
                                    return try! .init(
                                        markdown: "**Enter** to Send, **⇧ Enter** for Newline"
                                    )

                                } else {
                                    return try! .init(
                                        markdown: "**⇧Enter** to Send, **Enter** for Newline"
                                    )
                                }
                            }()
                        )
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5))
                        .padding(.horizontal, 8)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    HStack(spacing: 8) {
                        if viewStore.chat.numberOfMessagesInContext > 0 {
                            Button {
                                guard let last = viewStore.messages.last else { return }
                                guard !(last.source == .breaker), !(last.source == .receiving)
                                else { return }

                                viewStore.send(.breakChat)
                            } label: {
                                Image(systemName: "fish")
                                    .frame(height: 44)
                            }
                            .buttonStyle(.borderless)
                            .help("Forget all history")
                        }

                        InputEditor(
                            placeholder: "What's in your mind?",
                            text: viewStore.binding(get: \.input, send: { .updateInput($0) }),
                            enterToSend: viewStore.enterToSend,
                            newlineAction: {
                                viewStore.send(.sendInputIfCan)
                            }
                        )
                        .focused($focusedField, equals: .input)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(5)
                        .frame(height: 56)
                    }
                    .padding(8)
                    .background(.thinMaterial, in: Rectangle())
                    .onAppear {
                        focusedField = .input
                    }
                }
                .overlay {
                    if viewStore.isTextModeEnabled {
                        TextEditor(
                            text: .constant(viewStore.chatContent)
                        )
                        .font(.body)
                    }
                }
            }
            .navigationTitle(viewStore.chat.name)
            .navigationSubtitle(viewStore.chat.prompt)
            .toolbar {
                Button {
                    viewStore.send(.updateEditChatPresented(true))
                } label: {
                    Image(systemName: "info.circle")
                }
                .help("Edit chat")
                .sheet(
                    isPresented: viewStore.binding(
                        get: \.isEditChatPresented,
                        send: { .updateEditChatPresented($0) }
                    )
                ) {
                    EditChatView(
                        chat: viewStore.chat,
                        cancelAction: {
                            viewStore.send(.updateEditChatPresented(false))
                        },
                        doneAction: { chat in
                            viewStore.send(.updateChat(chat))
                            viewStore.send(.updateEditChatPresented(false))
                        }
                    )
                }

                Button {
                    viewStore.send(.tryClearAllMessages)
                } label: {
                    Image(systemName: "xmark")
                }
                .disabled(viewStore.messages.isEmpty)
                .help("Clear all messages")

                Button {
                    viewStore.send(.toggleTextModeEnabled)
                } label: {
                    Image(systemName: "doc.plaintext")
                        .foregroundColor(viewStore.isTextModeEnabled ? .accentColor : nil)
                }
                .disabled(viewStore.messages.isEmpty)
                .help("Toggle text mode")

                Button {
                    viewStore.send(.updateFileExporterPresented(true))
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewStore.messages.isEmpty)
                .help("Export as Markdown")
                .fileExporter(
                    isPresented: viewStore.binding(
                        get: \.isFileExporterPresented,
                        send: { .updateFileExporterPresented($0) }
                    ),
                    document: ChatDocument(
                        data: viewStore.chatContent.data(using: .utf8)
                    ),
                    contentType: .markdown,
                    defaultFilename: {
                        let now = Date()
                        let year = now.formatted(.dateTime.year(.defaultDigits))
                        let month = now.formatted(.dateTime.month(.twoDigits))
                        let day = now.formatted(.dateTime.day(.twoDigits))
                        let hour = now.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)))
                        let minute = now.formatted(.dateTime.minute(.twoDigits))
                        let second = now.formatted(.dateTime.second(.twoDigits))

                        return "\(viewStore.chat.name)-\(year).\(month).\(day)-\(hour).\(minute).\(second)"
                    }()
                ) { result in
                    #if DEBUG
                    switch result {
                    case .success(let url):
                        print("Exported to \(url)")
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    #endif
                }
            }
            .alert(
                store.scope(state: \.alert),
                dismiss: .dismissAlert
            )
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(
            store: .init(
                initialState: DetailReducer.State(
                    chat: .init(
                        id: .init(1),
                        name: "闲聊",
                        model: .gpt_3_5_turbo,
                        prompt: "语言简洁易懂的博士",
                        temperature: 0.3,
                        numberOfMessagesInContext: 4,
                        updatedAt: .distantPast
                    ),
                    messages: [
                        .init(
                            id: .init("1"),
                            chatID: .init(1),
                            source: .me,
                            content: "你好"
                        ),
                        .init(
                            id: .init("2"),
                            chatID: .init(1),
                            source: .sensei,
                            content: "你好，我能怎么帮助你？"
                        ),
                    ],
                    enterToSend: true,
                    input: "",
                    isEditChatPresented: false,
                    isTextModeEnabled: false,
                    isFileExporterPresented: false
                ),
                reducer: DetailReducer()
            )
        )
        .frame(width: 400, height: 400)
    }
}
