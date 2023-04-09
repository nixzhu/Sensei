import Foundation
import Ananda
import CustomDump

enum API {
    enum Error: Swift.Error, LocalizedError {
        case missingAPIKey
        case invalidURL
        case networkFailed
        case invalidResponse(Int, String)
        case invalidContent(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing API key"
            case .invalidURL:
                return "Invalid URL"
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
    ) async throws -> AsyncThrowingStream<String, Swift.Error> {
        let apiKey = Settings.apiKey

        guard !apiKey.isEmpty else {
            throw Error.missingAPIKey
        }

        let host: String = {
            let customHost = Settings.customHost

            if customHost.isEmpty {
                return "api.openai.com"
            } else {
                return customHost
            }
        }()

        guard let url = URL(string: "https://\(host)/v1/chat/completions") else {
            throw Error.invalidURL
        }

        var urlRequest = URLRequest(url: url)

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
            let stream: Bool
            let messages: [Message]
        }

        let input = Input(
            model: model.rawValue,
            temperature: temperature,
            stream: true,
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

        let (result, response) = try await URLSession.shared.bytes(for: urlRequest)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw Error.networkFailed
        }

        guard 200...299 ~= httpURLResponse.statusCode else {
            let errorJSONString: String = try await {
                var string = ""

                for try await line in result.lines {
                    string += line
                }

                return string
            }()

            #if DEBUG
            print("errorJSONString:", errorJSONString)
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

            let output = Output(jsonString: errorJSONString)

            throw Error.invalidResponse(httpURLResponse.statusCode, output.error.code)
        }

        struct StreamOutput: AnandaModel {
            struct Choice: AnandaModel {
                struct Delta: AnandaModel {
                    let content: String?

                    init(json: AnandaJSON) {
                        content = json.content.string
                    }
                }

                let delta: Delta
                let index: Int
                let finishReason: String?

                init(json: AnandaJSON) {
                    delta = .init(json: json.delta)
                    index = json.index.int()
                    finishReason = json.finish_reason.string
                }
            }

            let id: String
            let object: String
            let created: Date
            let model: String
            let choices: [Choice]

            init(json: AnandaJSON) {
                id = json.id.string()
                object = json.object.string()
                created = json.created.date()
                model = json.model.string()
                choices = json.choices.array().map { .init(json: $0) }
            }
        }

        return AsyncThrowingStream<String, Swift.Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    for try await line in result.lines {
                        #if DEBUG
                        print("line:", line)
                        #endif

                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8)
                        {
                            let output = StreamOutput(jsonData: data)

                            if let content = output.choices.first?.delta.content {
                                continuation.yield(content)
                            }

                            if output.choices.first?.finishReason == "stop" {
                                break
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
