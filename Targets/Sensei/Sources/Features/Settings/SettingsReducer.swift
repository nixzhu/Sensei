import SwiftUI
import ComposableArchitecture

struct SettingsReducer: Reducer {
    struct State: Equatable {
        var customHost: String
        var apiKey: String
        var enterToSend: Bool
    }

    enum Action: Equatable {
        case updateCustomHost(String)
        case updateAPIKey(String)
        case updateEnterToSend(Bool)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .updateCustomHost(let customHost):
                state.customHost = customHost
                return .none
            case .updateAPIKey(let apiKey):
                state.apiKey = apiKey
                return .none
            case .updateEnterToSend(let enterToSend):
                state.enterToSend = enterToSend
                return .none
            }
        }
    }
}
