import Foundation

@MainActor
final class ActionEngine {
    private let controller: ControllerService
    private let mouse: MouseInjector

    private var timer: Timer?

    // Accumulate sub-pixel deltas so low stick values still move.
    private var accumX: Double = 0
    private var accumY: Double = 0

    private var hasPrevState: Bool = false
    private var prevState = GamepadState()

    private var scrollAccumulator: Double = 0

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
        hasPrevState = false
        prevState = GamepadState()
        scrollAccumulator = 0
    }

    private func tick(dt: Double) {
        guard controller.isConnected else {
            hasPrevState = false
            scrollAccumulator = 0
            return
        }

        let state = controller.state
        if !hasPrevState {
            // Avoid firing clicks if the user enables while holding a trigger.
            prevState = state
            hasPrevState = true
            return
        }

        handleMovement(state: state, dt: dt)
        handleMouseButtons(state: state)
        handleScroll(state: state, dt: dt)

        prevState = state
    }

    private func handleMovement(state: GamepadState, dt: Double) {
        let (x, y) = applyDeadZone(x: state.leftX, y: state.leftY, deadZone: Mapping.stickDeadZone)
        if x == 0, y == 0 {
            accumX = 0
            accumY = 0
            return
        }

        let speed = Double(Mapping.cursorSpeedPixelsPerSecond)
        accumX += Double(x) * speed * dt
        accumY += Double(y) * speed * dt

        let dx = Int(accumX.rounded(.towardZero))
        let dy = Int(accumY.rounded(.towardZero))
        if dx == 0, dy == 0 { return }

        accumX -= Double(dx)
        accumY -= Double(dy)

        let leftButtonDown = state.r2 > Mapping.triggerDownThreshold

        // GameController Y is positive-up; Quartz mouse coords are positive-down.
        mouse.moveBy(dx: dx, dy: -dy, dragging: leftButtonDown)
    }

    private func handleMouseButtons(state: GamepadState) {
        let leftDownNow = state.r2 > Mapping.triggerDownThreshold
        let leftDownWas = prevState.r2 > Mapping.triggerDownThreshold
        if leftDownNow && !leftDownWas { mouse.leftDownAtCurrentCursor() }
        if !leftDownNow && leftDownWas { mouse.leftUpAtCurrentCursor() }

        let rightDownNow = state.l2 > Mapping.triggerDownThreshold
        let rightDownWas = prevState.l2 > Mapping.triggerDownThreshold
        if rightDownNow && !rightDownWas { mouse.rightDownAtCurrentCursor() }
        if !rightDownNow && rightDownWas { mouse.rightUpAtCurrentCursor() }

        if state.l1 && !prevState.l1 { mouse.otherButtonDown(buttonNumber: Mapping.mouseButton4Number) }
        if !state.l1 && prevState.l1 { mouse.otherButtonUp(buttonNumber: Mapping.mouseButton4Number) }

        if state.r1 && !prevState.r1 { mouse.otherButtonDown(buttonNumber: Mapping.mouseButton5Number) }
        if !state.r1 && prevState.r1 { mouse.otherButtonUp(buttonNumber: Mapping.mouseButton5Number) }
    }

    private func handleScroll(state: GamepadState, dt: Double) {
        let up = state.dpadUp
        let down = state.dpadDown

        if (up && down) || (!up && !down) {
            scrollAccumulator = 0
            return
        }

        scrollAccumulator += dt
        let interval = 1.0 / Mapping.scrollRepeatHz

        while scrollAccumulator >= interval {
            scrollAccumulator -= interval
            let delta: Int32 = up ? Mapping.scrollDeltaPixels : -Mapping.scrollDeltaPixels
            mouse.scroll(deltaY: delta)
        }
    }

    private func applyDeadZone(x: Float, y: Float, deadZone: Float) -> (Float, Float) {
        let mag = sqrt(x * x + y * y)
        if mag < deadZone { return (0, 0) }

        // Scale so movement ramps smoothly from the edge of the dead zone.
        let scaled = (mag - deadZone) / (1 - deadZone)
        return ((x / mag) * scaled, (y / mag) * scaled)
    }
}
