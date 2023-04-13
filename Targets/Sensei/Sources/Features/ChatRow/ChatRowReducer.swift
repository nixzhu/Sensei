import SwiftUI
import AppKit
import ComposableArchitecture

struct ChatRowReducer: Reducer {
    typealias State = Chat

    enum Action: Equatable {
        case tryDeleteChat
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .tryDeleteChat:
                return .none
            }
        }
    }
}
