import SwiftUI

struct HistoryOverlayView: View {
    @Binding var showHistory: Bool
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                HStack {
                    Text("History")
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Button(action: { appState.clearHistory() }) {
                        Text("Clear")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(appState.history.isEmpty)

                    Button(action: { showHistory = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)

                if appState.history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary.opacity(0.5))

                        Text("No history yet")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text("Your transcriptions will appear here")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(appState.history) { entry in
                            HistoryRow(entry: entry)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        appState.deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        TextInsertionService.shared.copyToClipboard(entry.processedText)
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }

                                    Button {
                                        appState.transcriptionText = entry.processedText
                                    } label: {
                                        Label("Load", systemImage: "arrow.up")
                                    }

                                    Button(role: .destructive) {
                                        appState.deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(width: 360)
            .background(Color(.windowBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color.primary.opacity(0.08)),
                alignment: .leading
            )
        }
        .background(Color.black.opacity(0.001))
        .onTapGesture {
            showHistory = false
        }
    }
}

struct HistoryRow: View {
    let entry: TranscriptionEntry
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: entry.mode.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.accentColor)

                Text(entry.mode.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(entry.timestamp, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.7))
            }

            Text(entry.processedText)
                .font(.system(size: 14))
                .lineSpacing(3)
                .lineLimit(4)
                .foregroundStyle(.primary)

            if entry.mode != .raw && entry.originalText != entry.processedText {
                Text("Original: \(entry.originalText)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
