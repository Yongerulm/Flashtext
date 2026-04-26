import Foundation

struct TranscriptionEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let originalText: String
    let processedText: String
    let mode: ProcessingMode
    let timestamp: Date
    let duration: TimeInterval
    let language: String?

    init(
        id: UUID = UUID(),
        originalText: String,
        processedText: String,
        mode: ProcessingMode,
        timestamp: Date = Date(),
        duration: TimeInterval,
        language: String? = nil
    ) {
        self.id = id
        self.originalText = originalText
        self.processedText = processedText
        self.mode = mode
        self.timestamp = timestamp
        self.duration = duration
        self.language = language
    }
}

enum ProcessingMode: String, Codable, CaseIterable, Identifiable {
    case raw = "Raw"
    case clean = "Clean"
    case smart = "Smart"
    case professional = "Professional"
    case friendly = "Friendly"
    case concise = "Concise"
    case assertive = "Assertive"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .raw: return "doc.text"
        case .clean: return "sparkles"
        case .smart: return "wand.and.stars"
        case .professional: return "briefcase"
        case .friendly: return "face.smiling"
        case .concise: return "text.badge.checkmark"
        case .assertive: return "exclamationmark.bubble"
        }
    }

    var description: String {
        switch self {
        case .raw: return "Exact transcription as spoken"
        case .clean: return "Grammar correction + punctuation"
        case .smart: return "Rewrite clearly and professionally"
        case .professional: return "Formal business tone"
        case .friendly: return "Warm and approachable"
        case .concise: return "Short and direct"
        case .assertive: return "Clear and confident"
        }
    }
}
