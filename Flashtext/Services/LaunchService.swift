import Foundation
import ServiceManagement

final class LaunchService {
    static let shared = LaunchService()

    private let service = SMAppService.mainApp
    private let defaultsKey = "launch_at_login"

    var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: defaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultsKey)
            if newValue {
                enable()
            } else {
                disable()
            }
        }
    }

    var serviceStatus: SMAppService.Status {
        service.status
    }

    private init() {}

    func enable() {
        do {
            try service.register()
            print("[LaunchService] Registered for login")
        } catch {
            print("[LaunchService] Failed to register: \(error)")
        }
    }

    func disable() {
        do {
            try service.unregister()
            print("[LaunchService] Unregistered from login")
        } catch {
            print("[LaunchService] Failed to unregister: \(error)")
        }
    }

    func syncWithSavedPreference() {
        if isEnabled {
            enable()
        }
    }
}
