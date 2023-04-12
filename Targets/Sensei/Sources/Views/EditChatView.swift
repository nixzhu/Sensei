import SwiftUI

struct EditChatView: View {
    @State private var chat: Chat
    private let cancelAction: () -> Void
    private let doneAction: (Chat) -> Void

    private var validName: String {
        chat.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validSenseiPrompt: String {
        chat.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !validName.isEmpty &&
            !validSenseiPrompt.isEmpty &&
            (0.0...1.0).contains(chat.temperature) &&
            (0...10).contains(chat.numberOfMessagesInContext)
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
        chat: Chat,
        cancelAction: @escaping () -> Void,
        doneAction: @escaping (Chat) -> Void
    ) {
        _chat = .init(initialValue: chat)
        self.cancelAction = cancelAction
        self.doneAction = doneAction
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Edit Chat")
                .bold()

            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                    
                    TextField(
                        "Name",
                        text: $chat.name
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
                        text: $chat.prompt,
                        enterToSend: nil,
                        newlineAction: nil
                    )
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(5)
                    .frame(height: 100)
                }
            }

            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model")
                    
                    Picker(
                        "",
                        selection: $chat.model
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
                        value: $chat.temperature,
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
                        value: $chat.numberOfMessagesInContext,
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
                    var chat = chat
                    chat.updatedAt = .init()

                    doneAction(chat)
                } label: {
                    Text("Done")
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

struct EditChatView_Previews: PreviewProvider {
    static var previews: some View {
        EditChatView(
            chat: .init(
                id: .init(1),
                name: "闲聊",
                model: .gpt_3_5_turbo,
                prompt: "语言简洁易懂的博士",
                temperature: 0.3,
                numberOfMessagesInContext: 4,
                updatedAt: .init()
            ),
            cancelAction: {},
            doneAction: { _ in }
        )
    }
}
