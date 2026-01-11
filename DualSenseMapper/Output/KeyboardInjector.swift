import Foundation
import CoreGraphics

enum SimpleKey {
    case returnKey
    case tab
    case option
    case z
    case x

    var keyCode: CGKeyCode {
        switch self {
        case .returnKey: return 0x24
        case .tab: return 0x30
        case .option: return 0x3A
        case .z: return 0x06
        case .x: return 0x07
        }
    }
}

final class KeyboardInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    func key(_ key: SimpleKey, down: Bool) {
        post(key.keyCode, down: down)
    }

    func tap(_ key: SimpleKey) {
        self.key(key, down: true)
        self.key(key, down: false)
    }

    func keyCode(_ code: CGKeyCode, down: Bool) {
        post(code, down: down)
    }

    func tapKeyCode(_ code: CGKeyCode) {
        keyCode(code, down: true)
        keyCode(code, down: false)
    }

    private func post(_ code: CGKeyCode, down: Bool) {
        guard let ev = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down) else { return }
        ev.post(tap: .cghidEventTap)
    }
}
