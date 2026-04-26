import SwiftUI

struct ProcessingIndicator: View {
    @EnvironmentObject private var appState: AppState
    @State private var rotation: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 2)
                    .frame(width: 18, height: 18)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: rotation)
            }

            Text(appState.isTranscribing ? "Transcribing..." : "Processing...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.08))
        )
        .onAppear {
            rotation = 360
        }
    }
}
