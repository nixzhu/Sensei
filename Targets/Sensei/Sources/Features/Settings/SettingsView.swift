import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    let store: StoreOf<SettingsReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Host")

                    TextField(
                        "api.openai.com",
                        text: viewStore.binding(
                            get: \.customHost,
                            send: { .updateCustomHost($0) }
                        )
                    )
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")

                    TextField(
                        "sk-",
                        text: viewStore.binding(
                            get: \.apiKey,
                            send: { .updateAPIKey($0) }
                        )
                    )
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Send Mode")

                    Picker(
                        "",
                        selection: viewStore.binding(
                            get: \.enterToSend,
                            send: { .updateEnterToSend($0) }
                        )
                    ) {
                        Text("Enter to Send").tag(true)
                        Text("⇧ Enter to Send").tag(false)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                }

                Spacer()
            }
            .padding()
        }
    }
}
