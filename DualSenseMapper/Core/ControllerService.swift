import Foundation
import GameController

// Milestone 4: Controller state reading via valueChangedHandler
@MainActor
final class ControllerService: ObservableObject {
    @Published private(set) var state = GamepadState()
    @Published private(set) var isConnected: Bool = false

    private var activeController: GCController?

    // Keep a strong reference to the active profile so its handlers stay alive.
    private var activeProfile: AnyObject?

    init() {
        // Menu bar apps are often “background” from GameController’s perspective.
        // Without this, valueChangedHandler may not fire unless the app is frontmost.
        GCController.shouldMonitorBackgroundEvents = true
        GCController.startWirelessControllerDiscovery(completionHandler: {})

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

        // Attach immediately if already connected.
        if let first = GCController.controllers().first {
            attach(first)
        }
    }

    @objc private func controllerDidConnect(_ note: Notification) {
        guard let controller = note.object as? GCController else { return }
        attach(controller)
    }

    @objc private func controllerDidDisconnect(_ note: Notification) {
        guard let controller = note.object as? GCController else { return }
        if controller == activeController {
            activeController = nil
            activeProfile = nil
            isConnected = false
            state = GamepadState()
        }
    }

    private func attach(_ controller: GCController) {
        activeController = controller
        isConnected = true

        // Ensure callbacks land on main; we mutate @Published state.
        controller.handlerQueue = .main

        // DualSense controllers should expose the extendedGamepad profile.
        if let eg = controller.extendedGamepad {
            activeProfile = eg
            wireExtendedInputs(eg)
        } else {
            activeProfile = nil
            state = GamepadState()
        }
    }

    private func wireExtendedInputs(_ pad: GCExtendedGamepad) {
        pad.valueChangedHandler = { [weak self] gamepad, _ in
            guard let self else { return }

            self.state = GamepadState(
                leftX: gamepad.leftThumbstick.xAxis.value,
                leftY: gamepad.leftThumbstick.yAxis.value,
                l2: gamepad.leftTrigger.value,
                r2: gamepad.rightTrigger.value,
                dpadUp: gamepad.dpad.up.isPressed,
                dpadDown: gamepad.dpad.down.isPressed,
                dpadLeft: gamepad.dpad.left.isPressed,
                dpadRight: gamepad.dpad.right.isPressed,
                l1: gamepad.leftShoulder.isPressed,
                r1: gamepad.rightShoulder.isPressed
            )
        }
    }
}
