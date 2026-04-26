import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

enum TextInsertionError: Error {
    case noFocusedElement
    case insertionFailed
    case accessibilityDenied
}

final class TextInsertionService {
    static let shared = TextInsertionService()

    private var originalClipboard: String?

    private init() {}

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("Paste: clipboard set (copy only)")
    }

    func pasteWithRetry(_ text: String, maxRetries: Int = 1) {
        paste(text)
    }

    func paste(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        saveClipboard()
        setClipboard(trimmed)
        print("Paste: clipboard set to transcribed text (trimmed)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }

            let success = self.sendCmdV()
            if success {
                print("Paste: cmd+v sent")
            } else {
                print("Paste: cmd+v failed, trying AX fallback")
                _ = self.insertViaAX(trimmed)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.restoreClipboard()
            }
        }
    }

    private func saveClipboard() {
        originalClipboard = NSPasteboard.general.string(forType: .string)
    }

    private func setClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func restoreClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let original = originalClipboard {
            pasteboard.setString(original, forType: .string)
            print("Paste: clipboard restored")
        }
        originalClipboard = nil
    }

    private func sendCmdV() -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            print("Paste: failed to create CGEventSource")
            return false
        }

        guard
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true),
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false),
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        else {
            print("Paste: failed to create CGEvents")
            return false
        }

        vDown.flags = .maskCommand
        vUp.flags = .maskCommand

        cmdDown.post(tap: .cghidEventTap)
        vDown.post(tap: .cghidEventTap)
        vUp.post(tap: .cghidEventTap)
        cmdUp.post(tap: .cghidEventTap)

        return true
    }

    private func insertViaAX(_ text: String) -> Bool {
        guard AXIsProcessTrusted() else {
            print("Paste: AX not trusted")
            return false
        }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let element = focusedElement else {
            print("Paste: no focused AX element")
            return false
        }

        let axElement = element as! AXUIElement

        var currentValue: CFTypeRef?
        let valueResult = AXUIElementCopyAttributeValue(
            axElement,
            kAXValueAttribute as CFString,
            &currentValue
        )

        let existingText: String
        if valueResult == .success, let value = currentValue as? String {
            existingText = value
        } else {
            existingText = ""
        }

        let setResult = AXUIElementSetAttributeValue(
            axElement,
            kAXValueAttribute as CFString,
            (existingText + text) as CFTypeRef
        )

        if setResult == .success {
            print("Paste: AX value set successfully")
        } else {
            print("Paste: AX value set failed: \(setResult)")
        }

        return setResult == .success
    }
}
