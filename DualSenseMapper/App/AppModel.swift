import SwiftUI
import AppKit

// Milestone 2: Added MouseInjector and KeyboardInjector for test buttons
@MainActor
final class AppModel: ObservableObject {
    @Published var enabled: Bool = false

    // Debug state (will show zeros until Milestone 4)
    @Published private(set) var debugState: GamepadState = .init()

    private let permission = PermissionService()
    private let mouse = MouseInjector()
    private let keyboard = KeyboardInjector()

    var accessibilityStatusText: String {
        permission.isTrusted ? "Granted" : "Not granted"
    }

    var controllerStatusText: String {
        "Disconnected"
    }

    func setEnabled(_ on: Bool) {
        if on {
            // Milestone 1: Check permission and prompt if needed
            if !permission.ensureTrusted(prompt: true) {
                // If not granted, force Enabled OFF
                enabled = false
                return
            }
            // Permission granted - enabled stays ON
            // (No functionality yet - will add in later milestones)
        } else {
            // Enabled OFF - nothing to do yet
        }
    }

    // Milestone 2: Test injection methods
    func testMouseClick() {
        guard permission.isTrusted else { return }
        mouse.leftClickAtCurrentCursor()
    }

    func testTypeEnter() {
        guard permission.isTrusted else { return }
        keyboard.tap(.returnKey)
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
