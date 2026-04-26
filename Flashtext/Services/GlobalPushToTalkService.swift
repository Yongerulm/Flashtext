import Foundation
import AppKit
import CoreGraphics
import ApplicationServices

final class GlobalPushToTalkService {
    static let shared = GlobalPushToTalkService()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?

    var onStart: (() -> Void)?
    var onStop: (() -> Void)?

    private let queue = DispatchQueue(label: "com.flashtext.ptt", qos: .userInitiated)

    private enum PTTState {
        case idle
        case recording
    }

    private var state: PTTState = .idle
    private var activeShortcut: ShortcutType = .controlOptionSpace

    private init() {
        print("PTT: service init")
    }

    func setShortcut(_ type: ShortcutType) {
        activeShortcut = type
        print("PTT: shortcut set to \(type.displayName) (keyCode: \(type.keyCode))")
    }

    func start() {
        guard eventTap == nil else {
            print("PTT: already running")
            return
        }

        guard checkAccessibilityPermission() else {
            print("PTT: accessibility trusted false — cannot start")
            return
        }

        print("PTT: starting with shortcut \(activeShortcut.displayName)")

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<GlobalPushToTalkService>.fromOpaque(refcon).takeUnretainedValue()
            return service.handleEvent(proxy: proxy, type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("PTT: FAILED to create event tap")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        guard let source = runLoopSource else {
            print("PTT: failed to create run loop source")
            return
        }

        queue.async { [weak self] in
            guard let self else { return }
            let rl = CFRunLoopGetCurrent()
            self.runLoop = rl
            CFRunLoopAddSource(rl, source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("PTT: event tap enabled on background thread")
            CFRunLoopRun()
            print("PTT: run loop exited")
        }
    }

    func restart() {
        print("PTT: restarting")
        stop()
        // Small delay to let the background thread fully exit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.start()
        }
    }

    func stop() {
        print("PTT: stopping")
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource, let rl = runLoop {
            CFRunLoopRemoveSource(rl, source, .commonModes)
            CFRunLoopStop(rl)
        }
        eventTap = nil
        runLoopSource = nil
        runLoop = nil
        state = .idle
    }

    private func handleEvent(proxy: CGEventTapProxy?, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("PTT: tap disabled by \(type == .tapDisabledByTimeout ? "timeout" : "user input") — re-enabling")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return nil
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        switch type {
        case .keyDown:
            let currentMods = flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
            let targetMods = activeShortcut.requiredModifiers
            let isMatch = keyCode == activeShortcut.keyCode && modifiersMatch(flags)

            print("PTT: keyDown keyCode=\(keyCode) flagsRaw=\(flags.rawValue) currentMods=\(currentMods.rawValue) targetMods=\(targetMods.rawValue) match=\(isMatch) state=\(state)")

            if state == .idle, isMatch {
                print("PTT: -> START RECORDING")
                state = .recording
                DispatchQueue.main.async { [weak self] in
                    self?.onStart?()
                }
                return nil
            }

            if state == .recording, keyCode == activeShortcut.keyCode, modifiersMatch(flags) {
                return nil
            }

        case .keyUp:
            let currentMods = flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
            let isMatch = keyCode == activeShortcut.keyCode && modifiersMatch(flags)

            print("PTT: keyUp keyCode=\(keyCode) flagsRaw=\(flags.rawValue) currentMods=\(currentMods.rawValue) match=\(isMatch) state=\(state)")

            if state == .recording, isMatch {
                print("PTT: -> STOP RECORDING (keyUp)")
                state = .idle
                DispatchQueue.main.async { [weak self] in
                    self?.onStop?()
                }
                return nil
            }

        case .flagsChanged:
            let currentMods = flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
            let stillMatches = modifiersMatch(flags)

            print("PTT: flagsChanged flagsRaw=\(flags.rawValue) currentMods=\(currentMods.rawValue) stillMatches=\(stillMatches) state=\(state)")

            if state == .recording, !stillMatches {
                print("PTT: -> STOP RECORDING (modifiers released)")
                state = .idle
                DispatchQueue.main.async { [weak self] in
                    self?.onStop?()
                }
                return nil
            }

        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    private func modifiersMatch(_ flags: CGEventFlags) -> Bool {
        let mask: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
        let current = flags.intersection(mask)
        let required = activeShortcut.requiredModifiers
        return current == required
    }

    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        print("PTT: accessibility trusted \(trusted)")
        return trusted
    }
}
