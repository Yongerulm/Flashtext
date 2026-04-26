import Foundation
import AVFoundation

enum AudioCaptureError: Error, LocalizedError {
    case permissionDenied
    case setupFailed
    case engineStartFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Microphone access denied. Enable it in System Settings > Privacy & Security > Microphone."
        case .setupFailed: return "Audio engine setup failed."
        case .engineStartFailed: return "Failed to start audio recording."
        }
    }
}

actor AudioCaptureService {
    private var audioEngine: AVAudioEngine?
    private var outputURL: URL?
    private var isRecording = false
    private var audioFile: AVAudioFile?
    private var audioLevel: Float = 0.0
    private var cancelRequested = false

    var currentLevel: Float { audioLevel }

    func startRecording() async throws -> URL {
        guard !isRecording else {
            return outputURL ?? URL(fileURLWithPath: "/dev/null")
        }

        let granted = await requestMicrophonePermission()
        guard granted else { throw AudioCaptureError.permissionDenied }

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let inputNode = engine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(UUID().uuidString).wav"
        let url = docs.appendingPathComponent(fileName)
        self.outputURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let file = try AVAudioFile(forWriting: url, settings: settings)
        self.audioFile = file

        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!

        let converter = AVAudioConverter(from: hardwareFormat, to: targetFormat)!

        // Mark as recording BEFORE installing tap so stopRecording can find us
        isRecording = true
        cancelRequested = false

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, _ in
            guard let self else { return }

            let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * 16000.0 / hardwareFormat.sampleRate)
            )!

            var error: NSError?
            converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if let data = convertedBuffer.floatChannelData?[0] {
                var sum: Float = 0
                let count = Int(convertedBuffer.frameLength)
                for i in 0..<count { sum += abs(data[i]) }
                self.audioLevel = min(sum / Float(count) * 20, 1.0)
            }

            Task { [weak self] in
                await self?.writeBuffer(convertedBuffer)
            }
        }

        engine.prepare()
        try engine.start()

        // If stop was requested while we were setting up, stop immediately
        if cancelRequested {
            return await stopRecording() ?? url
        }

        return url
    }

    func stopRecording() async -> URL? {
        cancelRequested = true

        guard isRecording else { return nil }

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false
        audioLevel = 0

        let url = outputURL
        outputURL = nil
        audioFile = nil
        return url
    }

    private func writeBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard let audioFile else { return }
        do {
            try audioFile.write(from: buffer)
        } catch {
            print("[Flashtext] Audio write error: \(error)")
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        if #available(macOS 14.0, *) {
            await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
