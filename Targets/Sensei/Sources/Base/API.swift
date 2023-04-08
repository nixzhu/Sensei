import Foundation
import Ananda
import CustomDump

enum API {
    enum Error: Swift.Error, LocalizedError {
        case missingAPIKey
        case networkFailed
        case invalidResponse(Int, String)
        case invalidContent(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing API key"
            case .networkFailed:
                return "Network failed"
            case .invalidResponse(let statusCode, let errorCode):
                return "Invalid response, status code: \(statusCode), error code: \(errorCode)"
            case .invalidContent(let content):
                return "Invalid content: \(content)"
            }
        }
    }
}

extension API {
    struct Message {
        enum Role: String {
            case system
            case user
            case assistant
        }

        let role: Role
        let content: String
    }

    static func chatCompletions(
        model: ChatGPTModel,
        temperature: Double,
        messages: [Message]
    ) async throws -> String {
        let apiKey = Settings.apiKey

        guard !apiKey.isEmpty else {
            throw Error.missingAPIKey
        }

        var urlRequest = URLRequest(
            url: .init(string: "https://api.openai.com/v1/chat/completions")!
        )

        urlRequest.httpMethod = "POST"

        urlRequest.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)",
        ]

        struct Input: Encodable {
            struct Message: Encodable {
                let role: String
                let content: String
            }

            let model: String
            let temperature: Double
            let messages: [Message]
        }

        let input = Input(
            model: model.rawValue,
            temperature: temperature,
            messages: messages.map {
                .init(
                    role: $0.role.rawValue,
                    content: $0.content
                )
            }
        )

        #if DEBUG
        customDump(input, name: "input")
        #endif

        urlRequest.httpBody = try JSONEncoder().encode(input)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw Error.networkFailed
        }

        guard httpURLResponse.statusCode == 200 else {
            #if DEBUG
            if let string = String(data: data, encoding: .utf8) {
                print("output:", string)
            }
            #endif

            struct Output: AnandaModel {
                struct Error: AnandaModel {
                    let message: String
                    let type: String
                    let code: String

                    init(json: AnandaJSON) {
                        message = json.message.string()
                        type = json.type.string()
                        code = json.code.string()
                    }
                }

                let error: Error

                init(json: AnandaJSON) {
                    error = .init(json: json.error)
                }
            }

            let output = Output(jsonData: data)

            throw Error.invalidResponse(httpURLResponse.statusCode, output.error.code)
        }

        #if DEBUG
        if let string = String(data: data, encoding: .utf8) {
            print("output:", string)
        }
        #endif

        struct Output: AnandaModel {
            struct Usage: AnandaModel {
                let promptTokens: Int
                let completionTokens: Int
                let totalTokens: Int

                init(json: AnandaJSON) {
                    promptTokens = json.prompt_tokens.int()
                    completionTokens = json.completion_tokens.int()
                    totalTokens = json.total_tokens.int()
                }
            }

            struct Choice: AnandaModel {
                struct Message: AnandaModel {
                    let role: String
                    let content: String

                    init(json: AnandaJSON) {
                        role = json.role.string()
                        content = json.content.string()
                    }
                }

                let message: Message
                let finishReason: String
                let index: Int

                init(json: AnandaJSON) {
                    message = .init(json: json.message)
                    finishReason = json.finish_reason.string()
                    index = json.index.int()
                }
            }

            let id: String
            let object: String
            let created: Date
            let model: String
            let usage: Usage
            let choices: [Choice]

            init(json: AnandaJSON) {
                id = json.id.string()
                object = json.object.string()
                created = json.created.date()
                model = json.model.string()
                usage = .init(json: json.usage)
                choices = json.choices.array().map { .init(json: $0) }
            }
        }

        let output = Output(jsonData: data)

        if let outputContent = output.choices.first?.message.content, !outputContent.isEmpty {
            return outputContent
        }

        throw Error.invalidContent(String(data: data, encoding: .utf8) ?? "")
    }
}
