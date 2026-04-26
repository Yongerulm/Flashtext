import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)

            TabView {
                GeneralSettingsTab()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }

                ShortcutSettingsTab()
                    .tabItem {
                        Label("Shortcuts", systemImage: "keyboard")
                    }

                AboutTab()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
            .padding(.bottom, 8)
        }
        .frame(minWidth: 520, minHeight: 360)
    }
}

struct GeneralSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var showKey = false

    var body: some View {
        Form {
            Section("API Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showKey {
                            TextField("OpenAI API Key", text: $appState.settings.apiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("OpenAI API Key", text: $appState.settings.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button(action: { showKey.toggle() }) {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Your API key is stored locally in UserDefaults.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Language") {
                Picker("Language Override", selection: $appState.settings.languageOverride) {
                    Text("Auto-detect").tag(nil as String?)
                    Text("English").tag("en" as String?)
                    Text("Spanish").tag("es" as String?)
                    Text("French").tag("fr" as String?)
                    Text("German").tag("de" as String?)
                    Text("Italian").tag("it" as String?)
                    Text("Portuguese").tag("pt" as String?)
                    Text("Dutch").tag("nl" as String?)
                    Text("Japanese").tag("ja" as String?)
                    Text("Chinese").tag("zh" as String?)
                    Text("Korean").tag("ko" as String?)
                    Text("Russian").tag("ru" as String?)
                }
                .pickerStyle(.menu)
            }

            Section("Output") {
                Toggle("Auto-copy to clipboard", isOn: $appState.settings.autoCopy)
                Toggle("Auto-insert into active field", isOn: $appState.settings.autoPaste)
            }

            Section("System") {
                Toggle("Launch at login", isOn: .init(
                    get: { LaunchService.shared.isEnabled },
                    set: { LaunchService.shared.isEnabled = $0 }
                ))
            }

            Section("Defaults") {
                Picker("Default Mode", selection: $appState.settings.defaultMode) {
                    ForEach(ProcessingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
    }
}

struct ShortcutSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Shortcut Configuration") {
                Picker("Push to Talk Shortcut", selection: $appState.activeShortcut) {
                    ForEach(ShortcutType.allCases) { shortcut in
                        Text(shortcut.displayName).tag(shortcut)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Active shortcut:")
                        .font(.system(size: 13))

                    Spacer()

                    ShortcutKeyView(label: appState.settings.activeShortcut.displayName)
                }
                .padding(.vertical, 4)

                Text("Press and hold to record. Release to stop.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Text("Requires Accessibility permission in System Settings.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ShortcutKeyView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Flashtext")
                .font(.system(size: 24, weight: .bold))

            Text("Version 1.0.1")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text("High-performance voice-to-text for macOS.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Link("www.vaitl.ai", destination: URL(string: "https://www.vaitl.ai")!)
                .font(.system(size: 12))
                .foregroundStyle(Color.accentColor)

            Text("© 2026 vaitl.ai")
                .font(.system(size: 11))
                .foregroundStyle(.secondary.opacity(0.7))

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
