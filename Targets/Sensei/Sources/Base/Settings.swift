import SwiftUI

enum Settings {
    @AppStorage("customHost") static var customHost = ""
    @AppStorage("apiKey") static var apiKey = ""
}
