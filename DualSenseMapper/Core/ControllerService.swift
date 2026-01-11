import Foundation
import GameController

// Milestone 3: Controller connect/disconnect detection only
@MainActor
final class ControllerService: ObservableObject {
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
        }
    }

    private func attach(_ controller: GCController) {
        activeController = controller
        isConnected = true
        // Milestone 3: Just detect connection
        // Will add input reading in Milestone 4
    }
}
