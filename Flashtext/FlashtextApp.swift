import SwiftUI
import Combine

@main
struct FlashtextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(AppState.shared)
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusBar()

        cancellable = AppState.shared.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.updateStatusBar(isRecording: isRecording)
            }
    }

    func applicationWillTerminate(_ notification: Notification) {
        GlobalPushToTalkService.shared.stop()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Flashtext")
        statusItem?.button?.action = #selector(showMenu)
        statusItem?.button?.target = self
        statusItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func updateStatusBar(isRecording: Bool) {
        let symbol = isRecording ? "waveform.circle.fill" : "waveform"
        let color: NSColor = isRecording ? .red : .controlTextColor
        statusItem?.button?.image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: isRecording ? "Recording" : "Flashtext"
        )?.withSymbolConfiguration(.init(paletteColors: [color]))
    }

    @objc private func showMenu() {
        guard let event = NSApp.currentEvent else { return }

        let menu = NSMenu()

        let recordingItem = NSMenuItem(title: AppState.shared.isRecording ? "Recording..." : "Idle", action: nil, keyEquivalent: "")
        recordingItem.isEnabled = false
        menu.addItem(recordingItem)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let historyItem = NSMenuItem(title: "History", action: #selector(openHistory), keyEquivalent: "")
        historyItem.target = self
        menu.addItem(historyItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Flashtext Settings"
            window.contentView = NSHostingView(rootView: SettingsView().environmentObject(AppState.shared))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func openHistory() {
        NSApp.activate(ignoringOtherApps: true)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 680),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Flashtext"
        window.contentView = NSHostingView(rootView: ContentView().environmentObject(AppState.shared))
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
