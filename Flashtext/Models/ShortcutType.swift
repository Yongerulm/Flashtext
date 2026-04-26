import Foundation
import CoreGraphics

enum ShortcutType: String, Codable, CaseIterable, Identifiable {
    case controlOptionSpace = "⌃ + ⌥ + Space"
    case optionY = "⌥ + Y"
    case controlY = "⌃ + Y"
    case optionSpace = "⌥ + Space"
    case controlSpace = "⌃ + Space"
    case optionShiftY = "⌥ + ⇧ + Y"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var requiredModifiers: CGEventFlags {
        switch self {
        case .controlOptionSpace:
            return [.maskControl, .maskAlternate]
        case .optionY:
            return .maskAlternate
        case .controlY:
            return .maskControl
        case .optionSpace:
            return .maskAlternate
        case .controlSpace:
            return .maskControl
        case .optionShiftY:
            return [.maskAlternate, .maskShift]
        }
    }

    var keyCode: Int64 {
        switch self {
        case .controlOptionSpace, .optionSpace, .controlSpace:
            return 49
        case .optionY, .controlY, .optionShiftY:
            return 16
        }
    }
}
