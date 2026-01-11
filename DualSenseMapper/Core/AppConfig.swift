import Foundation

// Bindable inputs we can reliably detect via current GameController wiring.
enum InputID: String, CaseIterable, Codable, Hashable {
    // D-pad
    case dpadUp, dpadDown, dpadLeft, dpadRight

    // Face buttons (DualSense names in comments)
    case faceSouth // Cross (X) == buttonA
    case faceEast  // Circle == buttonB
    case faceWest  // Square == buttonX
    case faceNorth // Triangle == buttonY

    // Shoulders + triggers
    case l1, r1
    case l2, r2

    // Stick clicks
    case l3, r3

    // System-ish
    case options
    case create
}

// UI-only controller parts. Includes things we don't bind yet.
enum VisualInputID: Codable, Hashable {
    case psButton // UI only; often OS-reserved
    case touchpadClick // UI only; marked unsupported for now

    case bindable(InputID)

    static var all: [VisualInputID] {
        var items: [VisualInputID] = [.psButton, .touchpadClick]
        items.append(contentsOf: InputID.allCases.map(VisualInputID.bindable))
        return items
    }
}

enum KeyModifier: Int, CaseIterable, Codable {
    case command
    case option
    case control
    case shift
}

struct KeySpec: Codable, Hashable {
    var keyCode: UInt16
    var modifiers: Set<KeyModifier> = []
}

enum Action: Codable, Hashable {
    case none

    // Mouse
    case mouseLeftHold
    case mouseRightHold
    case mouseMiddleClick
    case mouseButton4
    case mouseButton5

    // Keyboard
    case keyTap(KeySpec)
    case keyHold(KeySpec)
    case keyCombo(KeySpec) // modifiers down + key tap + modifiers up
}

struct AppConfig: Codable, Hashable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = Self.currentSchemaVersion

    // For digital triggers (L2/R2) mapping.
    var triggerThreshold: Float = 0.60

    // One input -> one action.
    var bindings: [InputID: Action] = [:]

    static func `default`() -> AppConfig {
        // Mirrors current hardcoded behavior.
        var cfg = AppConfig()

        cfg.bindings[.faceSouth] = .mouseLeftHold
        cfg.bindings[.l2] = .mouseRightHold
        cfg.bindings[.l1] = .mouseButton4
        cfg.bindings[.r1] = .mouseButton5

        cfg.bindings[.dpadLeft] = .keyHold(KeySpec(keyCode: 0x06)) // Z
        cfg.bindings[.dpadRight] = .keyHold(KeySpec(keyCode: 0x07)) // X
        cfg.bindings[.dpadUp] = .keyCombo(KeySpec(keyCode: 0x30, modifiers: [.option])) // Option+Tab

        return cfg
    }
}
