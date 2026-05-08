import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    @Published var transcriptionText: String = ""
    @Published var isTranscribing = false
    @Published var isProcessing = false
    @Published var currentMode: ProcessingMode = .smart
    @Published var history: [TranscriptionEntry] = []
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var livePreview: String = ""
    @Published var permissionsMissing: String?

    var settings = AppSettings.shared

    // Published proxy for Settings UI binding
    @Published var activeShortcut: ShortcutType {
        didSet {
            settings.activeShortcut = activeShortcut
        }
    }

    private let audioService = AudioCaptureService()
    private let whisperService = WhisperService()
    private let textService = TextProcessingService()
    private let pttService = GlobalPushToTalkService.shared

    private var recordingURL: URL?
    private var recordingStartTime: Date?
    private var levelTimer: Timer?
    private var pendingStop = false
    private var shortcutCancellable: AnyCancellable?
    private var modeCancellable: AnyCancellable?

    private var historyFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Flashtext", isDirectory: true)
            .appendingPathComponent("history.json")
    }

    init() {
        activeShortcut = settings.activeShortcut
        currentMode = settings.defaultMode
        loadHistory()
        setupPushToTalk()
        LaunchService.shared.syncWithSavedPreference()

        // Restart PTT service when shortcut changes in Settings
        shortcutCancellable = $activeShortcut
            .dropFirst()
            .sink { [weak self] newShortcut in
                print("[AppState] Shortcut changed to \(newShortcut.displayName), restarting PTT service")
                self?.pttService.setShortcut(newShortcut)
                self?.pttService.restart()
            }

        // Sync currentMode when defaultMode changes in Settings
        modeCancellable = settings.$defaultMode
            .dropFirst()
            .sink { [weak self] newMode in
                print("[AppState] Mode changed to \(newMode.displayName)")
                self?.currentMode = newMode
            }
    }

    private func setupPushToTalk() {
        pttService.setShortcut(settings.activeShortcut)

        pttService.onStart = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.startRecording()
            }
        }
        pttService.onStop = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.stopRecording()
            }
        }
        pttService.start()
    }

    func startRecording() async {
        guard !isRecording else { return }

        if !pttService.checkAccessibilityPermission() {
            permissionsMissing = "Flashtext needs Accessibility access. Go to System Settings > Privacy & Security > Accessibility and enable Flashtext."
            showError(permissionsMissing!)
            return
        }

        guard settings.isConfigured else {
            showError("Please enter your OpenAI API key in Settings.")
            return
        }

        do {
            recordingURL = try await audioService.startRecording()
            isRecording = true
            pendingStop = false
            recordingStartTime = Date()
            transcriptionText = ""
            livePreview = "Listening..."
            startLevelMonitoring()

            // Race condition protection: if stop was requested while we were awaiting startRecording
            if pendingStop {
                pendingStop = false
                await stopRecording()
            }
        } catch {
            pendingStop = false
            showError(error.localizedDescription)
        }
    }

    func stopRecording() async {
        guard isRecording else {
            // If startRecording hasn't finished yet, mark that we want to stop as soon as it does
            pendingStop = true
            return
        }
        pendingStop = false

        isRecording = false
        audioLevel = 0
        livePreview = "Processing..."
        stopLevelMonitoring()

        guard let url = await audioService.stopRecording() else {
            showError("No audio recorded.")
            return
        }

        let duration = Date().timeIntervalSince(recordingStartTime ?? Date())
        await transcribeAndProcess(audioURL: url, duration: duration)
    }

    private func transcribeAndProcess(audioURL: URL, duration: TimeInterval) async {
        isTranscribing = true
        defer { isTranscribing = false }

        do {
            let rawText = try await whisperService.transcribe(
                audioURL: audioURL,
                apiKey: settings.apiKey,
                language: settings.languageOverride
            )

            transcriptionText = rawText

            if currentMode == .raw {
                finalizeEntry(original: rawText, processed: rawText, duration: duration)
                return
            }

            isProcessing = true
            defer { isProcessing = false }

            let processedText = try await textService.process(
                text: rawText,
                mode: currentMode,
                apiKey: settings.apiKey
            )

            finalizeEntry(original: rawText, processed: processedText, duration: duration)

        } catch {
            if let whisperError = error as? WhisperError {
                showError(whisperError.localizedDescription)
            } else if let textError = error as? TextProcessingError {
                showError(textError.localizedDescription)
            } else {
                showError("An unexpected error occurred: \(error.localizedDescription)")
            }
        }

        try? FileManager.default.removeItem(at: audioURL)
    }

    private func finalizeEntry(original: String, processed: String, duration: TimeInterval) {
        let entry = TranscriptionEntry(
            originalText: original,
            processedText: processed,
            mode: currentMode,
            duration: duration,
            language: settings.languageOverride
        )

        history.insert(entry, at: 0)
        if history.count > 50 { history = Array(history.prefix(50)) }
        saveHistory()

        if settings.autoCopy {
            TextInsertionService.shared.copyToClipboard(processed)
        }

        if settings.autoPaste {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                TextInsertionService.shared.paste(processed)
            }
        }

        transcriptionText = processed
        livePreview = ""
    }

    func deleteEntry(_ entry: TranscriptionEntry) {
        history.removeAll { $0.id == entry.id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func retryEntry(_ entry: TranscriptionEntry) async {
        guard settings.isConfigured else {
            showError("Please configure your OpenAI API key.")
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let processedText = try await textService.process(
                text: entry.originalText,
                mode: currentMode,
                apiKey: settings.apiKey
            )

            let newEntry = TranscriptionEntry(
                originalText: entry.originalText,
                processedText: processedText,
                mode: currentMode,
                duration: entry.duration,
                language: entry.language
            )

            if let index = history.firstIndex(where: { $0.id == entry.id }) {
                history[index] = newEntry
                saveHistory()
            }
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { [weak self] in
                guard let self else { return }
                let level = await self.audioService.currentLevel
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.05)) {
                        self.audioLevel = level
                    }
                }
            }
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            try FileManager.default.createDirectory(at: historyFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: historyFileURL)
        } catch {
            print("[Flashtext] Failed to save history: \(error)")
        }
    }

    private func loadHistory() {
        do {
            let data = try Data(contentsOf: historyFileURL)
            history = try JSONDecoder().decode([TranscriptionEntry].self, from: data)
        } catch {
            history = []
        }
    }

    func showError(_ message: String) {
        errorMessage = message
        print("[Flashtext] Error: \(message)")
    }
}
