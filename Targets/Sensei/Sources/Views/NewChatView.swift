import SwiftUI

struct NewChatView: View {
    private let cancelAction: () -> Void
    private let doneAction: (LocalChat) -> Void
    @State private var name = ""
    @State private var model = ChatGPTModel.gpt_3_5_turbo
    @State private var prompt = ""
    @State private var temperature = 0.3
    @State private var numberOfMessagesInContext = 4

    private var validName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validSenseiPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !validName.isEmpty &&
            !validSenseiPrompt.isEmpty &&
            (0.0...1.0).contains(temperature) &&
            (0...10).contains(numberOfMessagesInContext)
    }

    private let temperatureFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    init(
        cancelAction: @escaping () -> Void,
        doneAction: @escaping (LocalChat) -> Void
    ) {
        self.cancelAction = cancelAction
        self.doneAction = doneAction
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("New Chat")
                .bold()

            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Host (Shared by all chats)")

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
                    Text("API Key (Shared by all chats)")

                    TextField(
                        "sk-",
                        text: Settings.$apiKey
                    )
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                }
            }

            Divider()

            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")

                    TextField(
                        "Name",
                        text: $name
                    )
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Prompt")

                    InputEditor(
                        placeholder: "Prompt",
                        text: $prompt,
                        onShiftEnter: {}
                    )
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                    .frame(height: 100)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Model")

                    Picker(
                        "",
                        selection: $model
                    ) {
                        ForEach(ChatGPTModel.allCases, id: \.self) { model in
                            Text(model.rawValue).tag(model)
                        }
                    }
                    .labelsHidden()
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Temperature (0-1)")

                    TextField(
                        "0.3",
                        value: $temperature,
                        formatter: temperatureFormatter
                    )
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Number of messages in context (0-10)")

                    TextField(
                        "4",
                        value: $numberOfMessagesInContext,
                        formatter: numberFormatter
                    )
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                }
            }

            Spacer()

            HStack(spacing: 0) {
                Button {
                    cancelAction()
                } label: {
                    Text("Cancel")
                }

                Spacer()

                Button {
                    let localChat = LocalChat(
                        name: validName,
                        model: model,
                        prompt: validSenseiPrompt,
                        temperature: temperature,
                        numberOfMessagesInContext: 4,
                        updatedAt: .init()
                    )

                    doneAction(localChat)
                } label: {
                    Text("Create")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 480)
        .background(Color(.windowBackgroundColor))
    }
}

struct NewChatView_Previews: PreviewProvider {
    static var previews: some View {
        NewChatView(
            cancelAction: {},
            doneAction: { _ in }
        )
    }
}
