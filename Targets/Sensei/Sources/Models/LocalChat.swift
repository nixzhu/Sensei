import Foundation
import GRDB

struct LocalChat: Codable, Identifiable, Hashable {
    var id: Int64?
    var name: String
    var model: ChatGPTModel
    var prompt: String
    var temperature: Double
    var numberOfMessagesInContext: Int
    var updatedAt: Date
}

extension LocalChat {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let model = Column(CodingKeys.model)
        static let prompt = Column(CodingKeys.prompt)
        static let temperature = Column(CodingKeys.temperature)
        static let numberOfMessagesInContext = Column(CodingKeys.numberOfMessagesInContext)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
}

extension LocalChat: FetchableRecord, MutablePersistableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension LocalChat: TableRecord, EncodableRecord {
    static var databaseTableName: String { "chat" }
}

extension LocalChat {
    static let messages = hasMany(LocalMessage.self)

    var messages: QueryInterfaceRequest<LocalMessage> {
        request(for: Self.messages)
    }
}

extension LocalChat {
    var chat: Chat {
        .init(
            id: .init(id!),
            name: name,
            model: model,
            prompt: prompt,
            temperature: temperature,
            numberOfMessagesInContext: numberOfMessagesInContext,
            updatedAt: updatedAt
        )
    }
}
