import Foundation

extension Action {
    func summary() -> String {
        switch self {
        case .none:
            return "None"

        case .mouseLeftHold:
            return "Mouse Left Hold"
        case .mouseRightHold:
            return "Mouse Right Hold"
        case .mouseMiddleClick:
            return "Mouse Middle"
        case .mouseButton4:
            return "Mouse Btn4"
        case .mouseButton5:
            return "Mouse Btn5"

        case let .keyTap(spec):
            return "Key Tap: \(KeyCatalog.name(for: spec.keyCode))\(modsSuffix(spec.modifiers))"
        case let .keyHold(spec):
            return "Key Hold: \(KeyCatalog.name(for: spec.keyCode))\(modsSuffix(spec.modifiers))"
        case let .keyCombo(spec):
            return "Key Combo: \(KeyCatalog.name(for: spec.keyCode))\(modsSuffix(spec.modifiers))"
        }
    }

    func shortLabel() -> String {
        switch self {
        case .none:
            return "—"

        case .mouseLeftHold:
            return "LMB"
        case .mouseRightHold:
            return "RMB"
        case .mouseMiddleClick:
            return "MMB"
        case .mouseButton4:
            return "Btn4"
        case .mouseButton5:
            return "Btn5"

        case let .keyTap(spec), let .keyHold(spec), let .keyCombo(spec):
            var s = KeyCatalog.name(for: spec.keyCode)
            if s.count > 8 { s = String(s.prefix(8)) }
            if !spec.modifiers.isEmpty { s = modsShort(spec.modifiers) + "+" + s }
            return s
        }
    }

    private func modsSuffix(_ mods: Set<KeyModifier>) -> String {
        if mods.isEmpty { return "" }
        return " (" + modsShort(mods).replacingOccurrences(of: "+", with: "+") + ")"
    }

    private func modsShort(_ mods: Set<KeyModifier>) -> String {
        let ordered: [KeyModifier] = [.command, .option, .control, .shift]
        let parts = ordered.compactMap { m -> String? in
            guard mods.contains(m) else { return nil }
            switch m {
            case .command: return "Cmd"
            case .option: return "Opt"
            case .control: return "Ctrl"
            case .shift: return "Shift"
            }
        }
        return parts.joined(separator: "+")
    }
}
