import SwiftUI
import AppKit
import ComposableArchitecture

struct ChatRowReducer: Reducer {
    enum Action: Equatable {
        case tryDeleteChat
    }

    var body: some Reducer<Chat, Action> {
        Reduce { _, action in
            switch action {
            case .tryDeleteChat:
                return .none
            }
        }
    }
}
