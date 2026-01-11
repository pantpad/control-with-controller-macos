import Foundation
import CoreGraphics

enum SimpleKey {
    case returnKey
}

final class KeyboardInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    func tap(_ key: SimpleKey) {
        let code: CGKeyCode
        switch key {
        case .returnKey: code = 0x24
        }
        post(code, down: true)
        post(code, down: false)
    }

    private func post(_ code: CGKeyCode, down: Bool) {
        guard let ev = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down) else { return }
        ev.post(tap: .cghidEventTap)
    }
}
