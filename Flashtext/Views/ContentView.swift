import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showHistory = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color(.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView(showHistory: $showHistory, showSettings: $showSettings)

                ScrollView {
                    VStack(spacing: 24) {
                        RecordingView()
                            .padding(.top, 20)

                        ModeSelectorView()
                            .padding(.horizontal, 20)

                        if !appState.transcriptionText.isEmpty {
                            ResultView()
                                .padding(.horizontal, 20)
                        }

                        if appState.isTranscribing || appState.isProcessing {
                            ProcessingIndicator()
                                .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }

            if showHistory {
                HistoryOverlayView(showHistory: $showHistory)
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(minWidth: 420, minHeight: 500)
        .alert("Error", isPresented: $appState.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
                .frame(minWidth: 520, minHeight: 360)
                .fixedSize()
        }
    }
}

struct HeaderView: View {
    @Binding var showHistory: Bool
    @Binding var showSettings: Bool
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Flashtext")
                    .font(.system(size: 16, weight: .semibold))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { showHistory.toggle() }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundStyle(showHistory ? Color.accentColor : .secondary)

                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
}
