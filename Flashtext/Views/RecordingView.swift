import SwiftUI

struct RecordingView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(appState.isRecording ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)

                if appState.isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(1 + CGFloat(appState.audioLevel) * 0.15)
                        .animation(.easeInOut(duration: 0.1), value: appState.audioLevel)
                }

                Button(action: {
                    Task {
                        if appState.isRecording {
                            await appState.stopRecording()
                        } else {
                            await appState.startRecording()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(appState.isRecording ? Color.red : Color.accentColor)
                            .frame(width: 100, height: 100)
                            .shadow(color: (appState.isRecording ? Color.red : Color.accentColor).opacity(0.3), radius: 20, x: 0, y: 8)

                        Image(systemName: appState.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }

            if appState.isRecording {
                AudioVisualizer()
                    .frame(height: 40)

                Text(appState.livePreview)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 4) {
                    Text("Tap to record")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)

                    Text("or press \(appState.settings.activeShortcut.displayName)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct AudioVisualizer: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red.opacity(0.6))
                    .frame(width: 4)
                    .frame(height: max(4, CGFloat.random(in: 4...32) * CGFloat(appState.audioLevel)))
                    .animation(.easeInOut(duration: 0.05).delay(Double(index) * 0.01), value: appState.audioLevel)
            }
        }
        .frame(height: 40)
    }
}
