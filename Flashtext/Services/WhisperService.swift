import Foundation

enum WhisperError: Error, LocalizedError {
    case invalidAPIKey
    case networkError
    case rateLimited
    case serverError
    case invalidAudio

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey: return "Invalid API key. Check your settings."
        case .networkError: return "Network error. Check your connection."
        case .rateLimited: return "Rate limit reached. Please wait."
        case .serverError: return "OpenAI server error. Try again shortly."
        case .invalidAudio: return "Audio file is invalid or too short."
        }
    }
}

actor WhisperService {
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String {
        guard !apiKey.isEmpty else { throw WhisperError.invalidAPIKey }

        guard let url = URL(string: baseURL) else {
            throw WhisperError.networkError
        }

        let boundary = "Boundary-\(UUID().uuidString)"

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: audioURL))
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        if let language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperError.networkError
        }

        switch httpResponse.statusCode {
        case 200...299:
            let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
            return result.text
        case 401:
            throw WhisperError.invalidAPIKey
        case 429:
            throw WhisperError.rateLimited
        case 500...599:
            throw WhisperError.serverError
        default:
            throw WhisperError.serverError
        }
    }
}

struct WhisperResponse: Codable {
    let text: String
}
