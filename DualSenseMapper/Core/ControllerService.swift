import Foundation
import GameController

// Milestone 4: Controller state reading via valueChangedHandler
@MainActor
final class ControllerService: ObservableObject {
    @Published private(set) var state = GamepadState()
    @Published private(set) var isConnected: Bool = false

    // Step 2: diagnostics to prove what GameController is delivering.
    @Published private(set) var diagnosticsText: String = ""
    @Published private(set) var lastEventText: String = "(no events yet)"

    private var activeController: GCController?

    // Keep a strong reference to the active profile so its handlers stay alive.
    private var activeProfile: AnyObject?

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df
    }()

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

        updateDiagnostics()
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
            lastEventText = "(no events yet)"
            updateDiagnostics()
        }
    }

    private func updateDiagnostics() {
        let count = GCController.controllers().count

        guard let c = activeController else {
            diagnosticsText = "GCController.controllers(): \(count)\nActive: (none)"
            return
        }

        let vendor = c.vendorName ?? "(nil)"
        let category = c.productCategory ?? "(nil)"
        let hasExtended = (c.extendedGamepad != nil) ? "1" : "0"
        let hasGamepad = (c.gamepad != nil) ? "1" : "0"
        let hasMicro = (c.microGamepad != nil) ? "1" : "0"

        diagnosticsText = "GCController.controllers(): \(count)\nVendor: \(vendor)\nCategory: \(category)\nProfiles: extended=\(hasExtended) gamepad=\(hasGamepad) micro=\(hasMicro)"
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

        updateDiagnostics()
    }

    private func wireExtendedInputs(_ pad: GCExtendedGamepad) {
        pad.valueChangedHandler = { [weak self] gamepad, element in
            guard let self else { return }

            let ts = Self.dateFormatter.string(from: Date())
            self.lastEventText = "\(ts) \(describeElement(element))"

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

    private func describeElement(_ element: GCControllerElement) -> String {
        var parts: [String] = [String(describing: type(of: element))]

        if let button = element as? GCControllerButtonInput {
            parts.append(String(format: "value=% .3f pressed=%d", button.value, button.isPressed ? 1 : 0))
        } else if let axis = element as? GCControllerAxisInput {
            parts.append(String(format: "value=% .3f", axis.value))
        } else if let dpad = element as? GCControllerDirectionPad {
            parts.append(String(format: "x=% .3f y=% .3f", dpad.xAxis.value, dpad.yAxis.value))
        }

        return parts.joined(separator: " ")
    }
}
