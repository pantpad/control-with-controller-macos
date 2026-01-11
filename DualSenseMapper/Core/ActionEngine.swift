import Foundation
import CoreGraphics

@MainActor
final class ActionEngine {
    private let controller: ControllerService
    private let mouse: MouseInjector
    private let keyboard: KeyboardInjector

    private var config: AppConfig

    private var timer: Timer?

    // Accumulate sub-pixel deltas so low stick values still move.
    private var accumX: Double = 0
    private var accumY: Double = 0

    private var hasPrevState: Bool = false
    private var prevState = GamepadState()

    private var scrollAccumulator: Double = 0

    init(controller: ControllerService, mouse: MouseInjector, keyboard: KeyboardInjector, config: AppConfig) {
        self.controller = controller
        self.mouse = mouse
        self.keyboard = keyboard
        self.config = config
    }

    func setConfig(_ newConfig: AppConfig) {
        if hasPrevState {
            releaseOutputs(state: prevState, config: config)
        }
        config = newConfig
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
            releaseOutputs(state: prevState, config: config)
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
                releaseOutputs(state: prevState, config: config)
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

        let prevPressed = pressedMap(from: prevState)
        let pressed = pressedMap(from: state)

        handleMovement(state: state, dt: dt, pressed: pressed)
        handleScroll(state: state, dt: dt)
        handleBindings(pressed: pressed, prevPressed: prevPressed)

        prevState = state
    }

    private func handleMovement(state: GamepadState, dt: Double, pressed: [InputID: Bool]) {
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

        let leftButtonDown = isMouseLeftHoldDown(pressed: pressed)

        // GameController Y is positive-up; Quartz mouse coords are positive-down.
        mouse.moveBy(dx: dx, dy: -dy, dragging: leftButtonDown)
    }

    private func pressedMap(from state: GamepadState) -> [InputID: Bool] {
        let threshold = config.triggerThreshold

        return [
            .dpadUp: state.dpadUp,
            .dpadDown: state.dpadDown,
            .dpadLeft: state.dpadLeft,
            .dpadRight: state.dpadRight,

            .faceSouth: state.cross,
            .faceEast: state.circle,
            .faceWest: state.square,
            .faceNorth: state.triangle,

            .l1: state.l1,
            .r1: state.r1,

            .l2: state.l2 > threshold,
            .r2: state.r2 > threshold,

            .l3: state.l3,
            .r3: state.r3,

            .options: state.options,
            .create: state.create,
        ]
    }

    private func isMouseLeftHoldDown(pressed: [InputID: Bool]) -> Bool {
        for (input, action) in config.bindings {
            guard pressed[input] == true else { continue }
            if case .mouseLeftHold = action { return true }
        }
        return false
    }

    private func handleBindings(pressed: [InputID: Bool], prevPressed: [InputID: Bool]) {
        for input in InputID.allCases {
            let now = pressed[input] ?? false
            let was = prevPressed[input] ?? false
            if now == was { continue }

            let action = config.bindings[input] ?? .none
            if case .none = action { continue }

            if now {
                performPress(action)
            } else {
                performRelease(action)
            }
        }
    }

    private func performPress(_ action: Action) {
        switch action {
        case .none:
            break

        case .mouseLeftHold:
            mouse.leftDownAtCurrentCursor()
        case .mouseRightHold:
            mouse.rightDownAtCurrentCursor()
        case .mouseMiddleClick:
            mouse.otherButtonDown(buttonNumber: 2)
            mouse.otherButtonUp(buttonNumber: 2)
        case .mouseButton4:
            mouse.otherButtonDown(buttonNumber: Mapping.mouseButton4Number)
        case .mouseButton5:
            mouse.otherButtonDown(buttonNumber: Mapping.mouseButton5Number)

        case let .keyTap(spec):
            tapKeySpec(spec)
        case let .keyCombo(spec):
            tapKeySpec(spec)
        case let .keyHold(spec):
            keySpecDown(spec)
        }
    }

    private func performRelease(_ action: Action) {
        switch action {
        case .none:
            break

        case .mouseLeftHold:
            mouse.leftUpAtCurrentCursor()
        case .mouseRightHold:
            mouse.rightUpAtCurrentCursor()
        case .mouseMiddleClick:
            break
        case .mouseButton4:
            mouse.otherButtonUp(buttonNumber: Mapping.mouseButton4Number)
        case .mouseButton5:
            mouse.otherButtonUp(buttonNumber: Mapping.mouseButton5Number)

        case .keyTap, .keyCombo:
            break
        case let .keyHold(spec):
            keySpecUp(spec)
        }
    }

    private func tapKeySpec(_ spec: KeySpec) {
        modifiersDown(spec.modifiers)
        keyboard.tapKeyCode(CGKeyCode(spec.keyCode))
        modifiersUp(spec.modifiers)
    }

    private func keySpecDown(_ spec: KeySpec) {
        modifiersDown(spec.modifiers)
        keyboard.keyCode(CGKeyCode(spec.keyCode), down: true)
    }

    private func keySpecUp(_ spec: KeySpec) {
        keyboard.keyCode(CGKeyCode(spec.keyCode), down: false)
        modifiersUp(spec.modifiers)
    }

    private func modifiersDown(_ mods: Set<KeyModifier>) {
        for mod in mods {
            keyboard.keyCode(modifierKeyCode(mod), down: true)
        }
    }

    private func modifiersUp(_ mods: Set<KeyModifier>) {
        for mod in mods {
            keyboard.keyCode(modifierKeyCode(mod), down: false)
        }
    }

    private func modifierKeyCode(_ mod: KeyModifier) -> CGKeyCode {
        switch mod {
        case .command: return 0x37
        case .option: return 0x3A
        case .control: return 0x3B
        case .shift: return 0x38
        }
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

    private func releaseOutputs(state: GamepadState, config: AppConfig) {
        let pressed = pressedMap(from: state)
        for (input, action) in config.bindings {
            guard pressed[input] == true else { continue }
            performRelease(action)
        }
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
