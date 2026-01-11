import Foundation

@MainActor
final class ActionEngine {
    private let controller: ControllerService
    private let mouse: MouseInjector

    private var timer: Timer?

    // Accumulate sub-pixel deltas so low stick values still move.
    private var accumX: Double = 0
    private var accumY: Double = 0

    init(controller: ControllerService, mouse: MouseInjector) {
        self.controller = controller
        self.mouse = mouse
    }

    func start() {
        stop()

        let interval = 1.0 / 120.0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick(dt: interval)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        accumX = 0
        accumY = 0
    }

    private func tick(dt: Double) {
        guard controller.isConnected else { return }

        let state = controller.state
        let (x, y) = applyDeadZone(x: state.leftX, y: state.leftY, deadZone: Mapping.stickDeadZone)
        if x == 0, y == 0 { return }

        let speed = Double(Mapping.cursorSpeedPixelsPerSecond)
        accumX += Double(x) * speed * dt
        accumY += Double(y) * speed * dt

        let dx = Int(accumX.rounded(.towardZero))
        let dy = Int(accumY.rounded(.towardZero))
        if dx == 0, dy == 0 { return }

        accumX -= Double(dx)
        accumY -= Double(dy)

        // GameController Y is positive-up; Quartz mouse coords are positive-down.
        mouse.moveBy(dx: dx, dy: -dy, dragging: false)
    }

    private func applyDeadZone(x: Float, y: Float, deadZone: Float) -> (Float, Float) {
        let mag = sqrt(x * x + y * y)
        if mag < deadZone { return (0, 0) }

        // Scale so movement ramps smoothly from the edge of the dead zone.
        let scaled = (mag - deadZone) / (1 - deadZone)
        return ((x / mag) * scaled, (y / mag) * scaled)
    }
}
