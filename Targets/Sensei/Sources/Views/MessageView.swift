import SwiftUI
import MarkdownUI

struct MessageView: View {
    let message: Message
    let clearAction: () -> Void
    let retryAction: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch message.source {
        case .me:
            HStack(spacing: 0) {
                Spacer(minLength: 44)

                Text(
                    message.content
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
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(message.content, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Divider()

                Button {
                    clearAction()
                } label: {
                    Label("Clear from bottom to this message", systemImage: "xmark")
                }
            }
        case .sensei:
            HStack(spacing: 0) {
                Markdown(
                    .init(message.content)
                )
                .markdownTheme(.sensei)
                .markdownCodeSyntaxHighlighter(.sensei(colorScheme: colorScheme))
                .markdownTextStyle(\.code) {
                    ForegroundColor(.purple)
                    BackgroundColor(.purple.opacity(0.1))
                }
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
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(message.content, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        case .error:
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text(
                        message.content
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
                        retryAction()
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
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            MessageView(
                message: .init(
                    id: .init("1"),
                    chatID: .init(1),
                    source: .me,
                    content: "Hello"
                ),
                clearAction: {},
                retryAction: {}
            )

            MessageView(
                message: .init(
                    id: .init("2"),
                    chatID: .init(1),
                    source: .sensei,
                    content: "How do you do?"
                ),
                clearAction: {},
                retryAction: {}
            )

            MessageView(
                message: .init(
                    id: .init("3"),
                    chatID: .init(1),
                    source: .error,
                    content: "Error"
                ),
                clearAction: {},
                retryAction: {}
            )

            MessageView(
                message: .init(
                    id: .init("4"),
                    chatID: .init(1),
                    source: .receiving,
                    content: ""
                ),
                clearAction: {},
                retryAction: {}
            )
        }
        .frame(width: 400, height: 400)
    }
}
