import Foundation
import ComposableArchitecture

private enum DatabaseManagerKey: DependencyKey {
    static let liveValue = DatabaseManager.shared
}

extension DependencyValues {
    var databaseManager: DatabaseManager {
        get { self[DatabaseManagerKey.self] }
        set { self[DatabaseManagerKey.self] = newValue }
    }
}
