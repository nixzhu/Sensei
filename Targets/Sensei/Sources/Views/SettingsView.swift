import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Host")

                TextField(
                    "api.openai.com",
                    text: Settings.$customHost
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
                    text: Settings.$apiKey
                )
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(5)
            }

            Spacer()
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
