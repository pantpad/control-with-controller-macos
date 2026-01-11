import Foundation

@MainActor
final class ActionEngine {
    private let controller: ControllerService
    private let mouse: MouseInjector
    private let keyboard: KeyboardInjector

    private var timer: Timer?

    // Accumulate sub-pixel deltas so low stick values still move.
    private var accumX: Double = 0
    private var accumY: Double = 0

    private var hasPrevState: Bool = false
    private var prevState = GamepadState()

    private var scrollAccumulator: Double = 0

    init(controller: ControllerService, mouse: MouseInjector, keyboard: KeyboardInjector) {
        self.controller = controller
        self.mouse = mouse
        self.keyboard = keyboard
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

        if hasPrevState {
            releaseOutputs(state: prevState)
        }

        accumX = 0
        accumY = 0
        hasPrevState = false
        prevState = GamepadState()
        scrollAccumulator = 0
    }

    private func tick(dt: Double) {
        guard controller.isConnected else {
            if hasPrevState {
                releaseOutputs(state: prevState)
            }
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
        handleKeyboard(state: state)

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

        let leftButtonDown = state.cross

        // GameController Y is positive-up; Quartz mouse coords are positive-down.
        mouse.moveBy(dx: dx, dy: -dy, dragging: leftButtonDown)
    }

    private func handleMouseButtons(state: GamepadState) {
        let leftDownNow = state.cross
        let leftDownWas = prevState.cross
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
        let y = applyAxisDeadZone(value: state.rightY, deadZone: Mapping.scrollDeadZone)
        if y == 0 {
            scrollAccumulator = 0
            return
        }

        // Positive stick Y (up) => positive wheel delta (up).
        scrollAccumulator += Double(y) * Double(Mapping.scrollSpeedPixelsPerSecond) * dt

        let delta = Int(scrollAccumulator.rounded(.towardZero))
        if delta == 0 { return }

        scrollAccumulator -= Double(delta)
        mouse.scroll(deltaY: Int32(delta))
    }

    private func handleKeyboard(state: GamepadState) {
        if state.dpadLeft && !prevState.dpadLeft { keyboard.key(.z, down: true) }
        if !state.dpadLeft && prevState.dpadLeft { keyboard.key(.z, down: false) }

        if state.dpadRight && !prevState.dpadRight { keyboard.key(.x, down: true) }
        if !state.dpadRight && prevState.dpadRight { keyboard.key(.x, down: false) }

        // D-pad up => Alt+Tab
        if state.dpadUp && !prevState.dpadUp {
            keyboard.key(.option, down: true)
            keyboard.tap(.tab)
        }
        if !state.dpadUp && prevState.dpadUp {
            keyboard.key(.option, down: false)
        }
    }

    private func releaseOutputs(state: GamepadState) {
        if state.cross { mouse.leftUpAtCurrentCursor() }
        if state.l2 > Mapping.triggerDownThreshold { mouse.rightUpAtCurrentCursor() }
        if state.l1 { mouse.otherButtonUp(buttonNumber: Mapping.mouseButton4Number) }
        if state.r1 { mouse.otherButtonUp(buttonNumber: Mapping.mouseButton5Number) }

        if state.dpadLeft { keyboard.key(.z, down: false) }
        if state.dpadRight { keyboard.key(.x, down: false) }
        if state.dpadUp { keyboard.key(.option, down: false) }
    }

    private func applyDeadZone(x: Float, y: Float, deadZone: Float) -> (Float, Float) {
        let mag = sqrt(x * x + y * y)
        if mag < deadZone { return (0, 0) }

        // Scale so movement ramps smoothly from the edge of the dead zone.
        let scaled = (mag - deadZone) / (1 - deadZone)
        return ((x / mag) * scaled, (y / mag) * scaled)
    }

    private func applyAxisDeadZone(value: Float, deadZone: Float) -> Float {
        let absValue = abs(value)
        if absValue < deadZone { return 0 }

        let scaled = (absValue - deadZone) / (1 - deadZone)
        return (value >= 0 ? 1 : -1) * scaled
    }
}
