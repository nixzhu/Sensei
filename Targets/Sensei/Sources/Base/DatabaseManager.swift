import Foundation
import Combine
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()

    let dbQueue: DatabaseQueue

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("createChat") { db in
            try db.create(table: "chat") { t in
                t.autoIncrementedPrimaryKey("id")

                t.column("name", .text)
                    .notNull()

                t.column("model", .text)
                    .notNull()

                t.column("prompt", .text)
                    .notNull()

                t.column("temperature", .double)
                    .notNull()

                t.column("numberOfMessagesInContext", .integer)
                    .notNull()

                t.column("updatedAt", .datetime)
                    .notNull()
            }
        }

        migrator.registerMigration("createMessage") { db in
            try db.create(table: "message") { t in
                t.autoIncrementedPrimaryKey("id")

                t.column("chatID", .integer)
                    .notNull()
                    .indexed()
                    .references("chat", onDelete: .cascade)

                t.column("source", .text)
                    .notNull()

                t.column("content", .text)
                    .notNull()
            }
        }

        return migrator
    }

    init() {
        let senseiDirectory = URL.applicationSupportDirectory.appendingPathComponent(
            Bundle.main.bundleIdentifier ?? "Sensei",
            isDirectory: true
        )

        try! FileManager.default.createDirectory(
            at: senseiDirectory,
            withIntermediateDirectories: true
        )

        let databaseURL = senseiDirectory.appendingPathComponent("db.sqlite")

        dbQueue = try! DatabaseQueue(path: databaseURL.path)

        try! migrator.migrate(dbQueue)
    }

    func chats() throws -> [LocalChat] {
        try dbQueue.read { db in
            try LocalChat.fetchAll(db)
        }
    }

    func messages(of chat: LocalChat) throws -> [LocalMessage] {
        try dbQueue.read { db in
            try chat.messages.fetchAll(db)
        }
    }

    func clearMessages(of chat: LocalChat) throws {
        _ = try dbQueue.write { db in
            try chat.messages.deleteAll(db)
        }
    }

    func clearErrorMessages(of chat: LocalChat) throws {
        _ = try dbQueue.write { db in
            try chat.messages
                .filter(LocalMessage.Columns.source == LocalMessage.Source.error.rawValue)
                .deleteAll(db)
        }
    }

    func deleteMessages(_ messages: [LocalMessage]) throws {
        _ = try dbQueue.write { db in
            for message in messages {
                try message.delete(db)
            }
        }
    }
}

extension DatabaseManager {
    @discardableResult
    func insert<Record: MutablePersistableRecord>(_ record: Record) throws -> Record {
        try dbQueue.write { db in
            try record.inserted(db)
        }
    }

    func update(_ record: some MutablePersistableRecord) throws {
        try dbQueue.write { db in
            try record.update(db)
        }
    }

    @discardableResult
    func delete(_ record: some MutablePersistableRecord) throws -> Bool {
        try dbQueue.write { db in
            try record.delete(db)
        }
    }
}
