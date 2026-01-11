import Foundation
import GameController

// Milestone 4: Added controller state reading via valueChangedHandler
@MainActor
final class ControllerService: ObservableObject {
    @Published private(set) var state = GamepadState()
    @Published private(set) var isConnected: Bool = false

    private var activeController: GCController?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect(_:)),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect(_:)),
            name: .GCControllerDidDisconnect,
            object: nil
        )

        // Check if controller already connected
        if let first = GCController.controllers().first {
            attach(first)
        }
    }

    @objc private func controllerDidConnect(_ note: Notification) {
        guard let c = note.object as? GCController else { return }
        attach(c)
    }

    @objc private func controllerDidDisconnect(_ note: Notification) {
        guard let c = note.object as? GCController else { return }
        if c == activeController {
            activeController = nil
            isConnected = false
            state = GamepadState()
        }
    }

    private func attach(_ controller: GCController) {
        activeController = controller
        isConnected = true

        // Milestone 4: Read controller input via extendedGamepad
        // (DualSense controllers support extendedGamepad profile)
        if let eg = controller.extendedGamepad {
            wireExtendedLikeInputs(eg)
        }
    }

    private func wireExtendedLikeInputs(_ pad: GCExtendedGamepad) {
        pad.valueChangedHandler = { [weak self] gamepad, _ in
            guard let self else { return }
            var s = self.state

            s.leftX = gamepad.leftThumbstick.xAxis.value
            s.leftY = gamepad.leftThumbstick.yAxis.value

            s.l2 = gamepad.leftTrigger.value
            s.r2 = gamepad.rightTrigger.value

            s.dpadUp = gamepad.dpad.up.isPressed
            s.dpadDown = gamepad.dpad.down.isPressed
            s.dpadLeft = gamepad.dpad.left.isPressed
            s.dpadRight = gamepad.dpad.right.isPressed

            s.l1 = gamepad.leftShoulder.isPressed
            s.r1 = gamepad.rightShoulder.isPressed

            self.state = s
        }
    }
}
