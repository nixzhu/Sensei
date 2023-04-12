import SwiftUI

enum Settings {
    @AppStorage("customHost") static var customHost = "api.openai.com"
    @AppStorage("apiKey") static var apiKey = ""
    @AppStorage("enterToSend") static var enterToSend = true
}
