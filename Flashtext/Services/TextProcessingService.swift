import Foundation

enum TextProcessingError: Error, LocalizedError {
    case invalidAPIKey
    case networkError
    case emptyInput

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey: return "Invalid API key."
        case .networkError: return "Network connection failed."
        case .emptyInput: return "No text to process."
        }
    }
}

actor TextProcessingService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    func process(text: String, mode: ProcessingMode, apiKey: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TextProcessingError.emptyInput
        }
        guard !apiKey.isEmpty else {
            throw TextProcessingError.invalidAPIKey
        }

        if mode == .raw { return text }

        guard let url = URL(string: baseURL) else {
            throw TextProcessingError.networkError
        }

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatMessage(role: "system", content: systemPrompt(for: mode)),
                ChatMessage(role: "user", content: text)
            ],
            temperature: 0.3,
            max_tokens: 2048
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TextProcessingError.networkError
        }

        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        return result.choices.first?.message.content ?? text
    }

    private func systemPrompt(for mode: ProcessingMode) -> String {
        switch mode {
        case .raw: return "Return the exact text without any changes."
        case .clean: return "Fix grammar and punctuation. Keep the original meaning and style. Only output the corrected text."
        case .smart: return "Rewrite the text clearly and professionally. Improve structure and flow while preserving the original meaning. Only output the rewritten text."
        case .professional: return "Rewrite in a formal, professional business tone. Be clear, respectful, and authoritative. Only output the rewritten text."
        case .friendly: return "Rewrite in a warm, approachable, and friendly tone. Be conversational and positive. Only output the rewritten text."
        case .concise: return "Make the text as short and direct as possible while keeping the key message. Remove filler words. Only output the rewritten text."
        case .assertive: return "Rewrite in a clear, confident, and assertive tone. Be direct and decisive. Only output the rewritten text."
        }
    }
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: ChatMessage
}
