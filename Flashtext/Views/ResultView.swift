import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Result")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if showCopied {
                    Label("Copied", systemImage: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.green)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 4)

            TextEditor(text: .constant(appState.transcriptionText))
                .font(.system(size: 15))
                .lineSpacing(4)
                .frame(minHeight: 80, maxHeight: 200)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.textBackgroundColor))
                )
                .scrollContentBackground(.hidden)

            HStack(spacing: 8) {
                Button {
                    TextInsertionService.shared.copyToClipboard(appState.transcriptionText)
                    withAnimation { showCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showCopied = false }
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    TextInsertionService.shared.pasteWithRetry(appState.transcriptionText, maxRetries: 1)
                } label: {
                    Label("Insert", systemImage: "arrow.down.doc")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button {
                    Task {
                        if let entry = appState.history.first(where: { $0.processedText == appState.transcriptionText }) {
                            await appState.retryEntry(entry)
                        }
                    }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .disabled(appState.isProcessing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
