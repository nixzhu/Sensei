import SwiftUI
import AppKit
import ComposableArchitecture

struct MessageRowReducer: Reducer {
    enum Action: Equatable {
        case clearFromBottomToThisMessage
        case retryChatIfCan(ScrollViewProxy)
        case copyMessage
    }

    var body: some Reducer<Message, Action> {
        Reduce { state, action in
            switch action {
            case .clearFromBottomToThisMessage:
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
