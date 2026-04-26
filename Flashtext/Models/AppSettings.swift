import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "openai_api_key") }
    }

    @Published var defaultMode: ProcessingMode {
        didSet { UserDefaults.standard.set(defaultMode.rawValue, forKey: "default_mode") }
    }

    @Published var autoCopy: Bool {
        didSet { UserDefaults.standard.set(autoCopy, forKey: "auto_copy") }
    }

    @Published var autoPaste: Bool {
        didSet { UserDefaults.standard.set(autoPaste, forKey: "auto_paste") }
    }

    @Published var languageOverride: String? {
        didSet {
            if let languageOverride {
                UserDefaults.standard.set(languageOverride, forKey: "language_override")
            } else {
                UserDefaults.standard.removeObject(forKey: "language_override")
            }
        }
    }

    @Published var activeShortcut: ShortcutType {
        didSet {
            UserDefaults.standard.set(activeShortcut.rawValue, forKey: "active_shortcut")
        }
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && apiKey.count > 20
    }

    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        self.defaultMode = ProcessingMode(rawValue: UserDefaults.standard.string(forKey: "default_mode") ?? "") ?? .smart
        self.autoCopy = UserDefaults.standard.bool(forKey: "auto_copy")
        self.autoPaste = UserDefaults.standard.bool(forKey: "auto_paste")
        self.languageOverride = UserDefaults.standard.string(forKey: "language_override")

        let storedRaw = UserDefaults.standard.string(forKey: "active_shortcut")
        if let raw = storedRaw, let shortcut = ShortcutType(rawValue: raw), shortcut != .optionY {
            self.activeShortcut = shortcut
            print("[Flashtext Settings] Loaded saved shortcut: \(shortcut.displayName)")
        } else {
            print("[Flashtext Settings] Saved shortcut invalid or was Option+Y. Resetting to default: \(ShortcutType.controlOptionSpace.displayName)")
            self.activeShortcut = .controlOptionSpace
            UserDefaults.standard.set(ShortcutType.controlOptionSpace.rawValue, forKey: "active_shortcut")
        }
    }
}
