import Foundation
import Tagged

struct Message: Identifiable, Hashable {
    typealias ID = Tagged<Message, String>

    enum Source {
        case me
        case sensei
        case error
        case breaker
        case receiving
    }

    let id: ID
    let chatID: Chat.ID
    let source: Source
    let content: String
}

extension Message {
    var localMessage: LocalMessage? {
        switch source {
        case .me:
            return .init(
                id: Int64(id.rawValue),
                chatID: chatID.rawValue,
                source: .me,
                content: content
            )
        case .sensei:
            return .init(
                id: Int64(id.rawValue),
                chatID: chatID.rawValue,
                source: .sensei,
                content: content
            )
        case .error:
            return .init(
                id: Int64(id.rawValue),
                chatID: chatID.rawValue,
                source: .error,
                content: content
            )
        case .breaker:
            return .init(
                id: Int64(id.rawValue),
                chatID: chatID.rawValue,
                source: .breaker,
                content: content
            )
        case .receiving:
            return nil
        }
    }
}
