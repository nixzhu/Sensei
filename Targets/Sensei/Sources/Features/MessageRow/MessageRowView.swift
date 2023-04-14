import SwiftUI
import ComposableArchitecture
import MarkdownUI

struct MessageRowView: View {
    let store: StoreOf<MessageRowReducer>
    @Environment(\.colorScheme) private var colorScheme
    @State private var over = false

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                switch viewStore.source {
                case .me:
                    HStack(spacing: 0) {
                        Spacer(minLength: 20)

                        Button {
                            viewStore.send(.tryClearFromBottomToThisMessage)
                        } label: {
                            Image(systemName: "xmark")
                                .opacity(over ? 1 : 0)
                        }
                        .help("Clear from bottom to this message")
                        .buttonStyle(.borderless)
                        .padding(.trailing, 10)

                        Button {
                            viewStore.send(.copyMessage)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .opacity(over ? 1 : 0)
                        }
                        .help("Copy")
                        .buttonStyle(.borderless)
                        .padding(.trailing, 10)

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
                            .foregroundColor(.accentColor.opacity(over ? 0.1 : 0.05))
                        )
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
                            .foregroundColor(.gray.opacity(over ? 0.1 : 0.05))
                        )

                        Button {
                            viewStore.send(.copyMessage)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .opacity(over ? 1 : 0)
                        }
                        .help("Copy")
                        .buttonStyle(.borderless)
                        .padding(.leading, 10)

                        Spacer(minLength: 20)
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
                                .foregroundColor(.red.opacity(over ? 0.1 : 0.05))
                            )

                            Button {
                                viewStore.send(.retryChatIfCan)
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.borderless)
                            .help("Retry")
                        }

                        Spacer(minLength: 20)
                    }
                case .breaker:
                    HStack(spacing: 2) {
                        Color.gray.opacity(over ? 0.5 : 0.35).frame(height: 1)

                        Image(systemName: "fish")
                        Image(systemName: "fish")
                        Image(systemName: "fish")

                        Color.gray.opacity(over ? 0.5 : 0.35).frame(height: 1)
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
                                .foregroundColor(.gray.opacity(over ? 0.1 : 0.05))
                            )

                        Spacer()
                    }
                }
            }
            .onHover {
                over = $0
            }
            .id(viewStore.id)
        }
    }
}

struct MessageRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            MessageRowView(
                store: .init(
                    initialState: .init(
                        id: .init("1"),
                        chatID: .init(1),
                        source: .me,
                        content: "Hello"
                    ),
                    reducer: MessageRowReducer()
                )
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
                )
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
                )
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
                )
            )
        }
        .frame(width: 400, height: 400)
    }
}
