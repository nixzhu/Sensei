import SwiftUI
import ComposableArchitecture
import MarkdownUI

struct MessageRowView: View {
    let store: StoreOf<MessageRowReducer>
    let scrollViewProxy: ScrollViewProxy
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                switch viewStore.source {
                case .me:
                    HStack(spacing: 0) {
                        Spacer(minLength: 44)

                        Text(
                            viewStore.content
                        )
                        .textSelection(.enabled)
                        .lineSpacing(4)
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                            .foregroundColor(.accentColor.opacity(0.05))
                        )
                    }
                    .contextMenu {
                        Button {
                            viewStore.send(.copyMessage)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button {
                            viewStore.send(.clearFromBottomToThisMessage)
                        } label: {
                            Label("Clear from bottom to this message", systemImage: "xmark")
                        }
                    }
                case .sensei:
                    HStack(spacing: 0) {
                        Markdown(
                            .init(viewStore.content)
                        )
                        .markdownTheme(.sensei)
                        .markdownCodeSyntaxHighlighter(.sensei(colorScheme: colorScheme))
                        .textSelection(.enabled)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                            .foregroundColor(.gray.opacity(0.05))
                        )

                        Spacer(minLength: 44)
                    }
                    .contextMenu {
                        Button {
                            viewStore.send(.copyMessage)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                case .error:
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Text(
                                viewStore.content
                            )
                            .lineSpacing(4)
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                                .foregroundColor(.red.opacity(0.05))
                            )

                            Button {
                                viewStore.send(.retryChatIfCan(scrollViewProxy))
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.borderless)
                            .help("Retry")
                        }

                        Spacer(minLength: 44)
                    }
                case .breaker:
                    HStack(spacing: 2) {
                        Color.gray.opacity(0.35).frame(height: 1)

                        Image(systemName: "fish")
                        Image(systemName: "fish")
                        Image(systemName: "fish")

                        Color.gray.opacity(0.35).frame(height: 1)
                    }
                case .receiving:
                    HStack(spacing: 0) {
                        ProgressView()
                            .scaleEffect(.init(width: 0.6, height: 0.6))
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                                .foregroundColor(.gray.opacity(0.05))
                            )

                        Spacer(minLength: 44)
                    }
                }
            }
            .id(viewStore.id)
        }
    }
}

struct MessageRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ScrollViewReader { scrollViewProxy in
                MessageRowView(
                    store: .init(
                        initialState: .init(
                            id: .init("1"),
                            chatID: .init(1),
                            source: .me,
                            content: "Hello"
                        ),
                        reducer: MessageRowReducer()
                    ),
                    scrollViewProxy: scrollViewProxy
                )

                MessageRowView(
                    store: .init(
                        initialState: .init(
                            id: .init("2"),
                            chatID: .init(1),
                            source: .sensei,
                            content: "How do you do?"
                        ),
                        reducer: MessageRowReducer()
                    ),
                    scrollViewProxy: scrollViewProxy
                )

                MessageRowView(
                    store: .init(
                        initialState: .init(
                            id: .init("3"),
                            chatID: .init(1),
                            source: .error,
                            content: "Error"
                        ),
                        reducer: MessageRowReducer()
                    ),
                    scrollViewProxy: scrollViewProxy
                )

                MessageRowView(
                    store: .init(
                        initialState: .init(
                            id: .init("4"),
                            chatID: .init(1),
                            source: .receiving,
                            content: ""
                        ),
                        reducer: MessageRowReducer()
                    ),
                    scrollViewProxy: scrollViewProxy
                )
            }
        }
        .frame(width: 400, height: 400)
    }
}