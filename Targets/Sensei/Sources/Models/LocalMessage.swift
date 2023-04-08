import Foundation
import GRDB

struct LocalMessage: Codable, Hashable {
    enum Source: String, Codable, DatabaseValueConvertible {
        case me
        case sensei
        case error
        case breaker
    }

    var id: Int64?
    var chatID: Int64
    var source: Source
    var content: String
}

extension LocalMessage {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let chatID = Column(CodingKeys.chatID)
        static let source = Column(CodingKeys.source)
        static let content = Column(CodingKeys.content)
    }
}

extension LocalMessage: FetchableRecord, MutablePersistableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension LocalMessage: TableRecord, EncodableRecord {
    static var databaseTableName: String { "message" }
}

extension LocalMessage {
    static let chat = belongsTo(LocalChat.self)

    var chat: QueryInterfaceRequest<LocalChat> {
        request(for: Self.chat)
    }
}

extension LocalMessage {
    var message: Message {
        .init(
            id: .init(String(id!)),
            chatID: .init(chatID),
            source: {
                switch source {
                case .me:
                    return .me
                case .sensei:
                    return .sensei
                case .error:
                    return .error
                case .breaker:
                    return .breaker
                }
            }(),
            content: content
        )
    }
}
