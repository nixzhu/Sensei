import SwiftUI
import AppKit
import ComposableArchitecture

struct MessageRowReducer: Reducer {
    typealias State = Message

    enum Action: Equatable {
        case tryClearFromBottomToThisMessage
        case retryChatIfCan
        case copyMessage
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .tryClearFromBottomToThisMessage:
                return .none
            case .retryChatIfCan:
                return .none
            case .copyMessage:
                NSPasteboard.general.declareTypes([.string], owner: nil)
                NSPasteboard.general.setString(state.content, forType: .string)
                return .none
            }
        }
    }
}
