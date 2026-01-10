This blueprint uses:

* SwiftUI `MenuBarExtra` for the menu bar UI. ([Apple Developer][1])
* GameController `GCDualSenseGamepad` (preferred) and `GCExtendedGamepad` (fallback), with `valueChangedHandler`. ([Apple Developer][2])
* Controller connect notifications `NSNotification.Name.GCControllerDidConnect/Disconnect`. ([Apple Developer][3])
* Accessibility trust prompt via `AXIsProcessTrustedWithOptions`. ([Apple Developer][4])
* Quartz event injection via `CGEvent` initializers + `post(tap:)` at `.cghidEventTap`. ([Apple Developer][5])
* Mouse button 4/5 via `.mouseEventButtonNumber`. ([Apple Developer][6])
* Smooth scrolling via `CGEvent` scroll wheel initializer. ([Apple Developer][7])

---

# DualSenseMapper BLUEPRINT

## What is a “menu bar utility”?

A **menu bar utility** is a normal macOS app whose primary interface is a persistent control in the macOS **menu bar** (top of the screen). In SwiftUI, this is implemented using `MenuBarExtra`. ([Apple Developer][1])

You click its icon in the menu bar to open a small menu/popup with controls (Enable/Disable, status, etc.).

---

## Critical Notes (do not skip)

1. **Event injection requires Accessibility permission.**
   Your mouse/keyboard injection is done by posting Quartz events (`CGEvent.post(tap:)`). This will not work unless the app is a trusted Accessibility client (TCC) — checked/prompted via `AXIsProcessTrustedWithOptions`. ([Apple Developer][8])

2. **The “Debug: live values” menu will NOT update unless AppModel republishes controller state.**
   SwiftUI views observing `AppModel` won’t automatically refresh just because a nested object (`ControllerService`) changes. Fix: mirror `ControllerService.$state` into a `@Published` property (`debugState`) in `AppModel` using Combine. (Code included below.)

3. All the TESTS below will be performed by the USER, DO NOT WRITE CODE TO AUTOMATICALY TEST

---

## Goal (v1)

Build a macOS 15 menu bar app that:

* Reads DualSense input using GameController:

  * Prefer `controller.dualSenseGamepad`
  * Fallback to `controller.extendedGamepad` ([Apple Developer][2])
* Updates a `GamepadState` snapshot via `valueChangedHandler`. ([Apple Developer][9])
* Injects mouse/keyboard using Quartz `CGEvent` + `.post(tap: .cghidEventTap)`. ([Apple Developer][5])
* Uses **one hardcoded mapping** (no profiles, no launch-at-login).

### Hardcoded mapping (v1)

* Left stick → move cursor
* R2 → left click (press/release)
* L2 → right click (press/release)
* D-pad up/down → scroll vertical
* L1 → mouse button 4
* R1 → mouse button 5

(Mouse buttons 4/5: implemented via `.mouseEventButtonNumber`.) ([Apple Developer][6])

---

# Milestones (build → MANUAL CHECK → proceed)

> IMPORTANT: “Tests” are **manual checks** you perform by using the UI/controller.
> Do **not** write automated unit tests for these milestones.

## Milestone 0 — App shell (menu bar UI only)

**Implement**

* SwiftUI app using `MenuBarExtra`. ([Apple Developer][1])
* Menu contains:

  * Toggle: Enabled
  * Text: Accessibility status
  * Text: Controller status
  * Quit button
  * Debug section (it will show zeros until Milestone 4)

**MANUAL CHECK**

* App appears in the menu bar.
* Toggle flips on/off.
* Quit works.

---

## Milestone 1 — Accessibility permission flow (no injection yet)

**Implement**

* `PermissionService.ensureTrusted(prompt:)` using `AXIsProcessTrustedWithOptions`. ([Apple Developer][4])
* When user toggles Enabled ON:

  * If not trusted: prompt, show Not granted, force Enabled OFF.

**MANUAL CHECK**

* Toggling Enabled ON prompts you to grant Accessibility (or shows Granted if already).
* If not granted, app does not enable mapping.

---

## Milestone 2 — Output injection (manual buttons in menu)

**Implement**

* `MouseInjector` and `KeyboardInjector` using `CGEvent` initializers + `.post(tap:)`. ([Apple Developer][5])
* Add temporary menu buttons:

  * “Test Mouse Click”
  * “Test Type Enter”

**MANUAL CHECK**

* After granting Accessibility:

  * “Test Mouse Click” clicks at cursor.
  * “Test Type Enter” presses Enter in TextEdit.

---

## Milestone 3 — Controller connect/disconnect status

**Implement**

* Observe `NSNotification.Name.GCControllerDidConnect` / `GCControllerDidDisconnect`. ([Apple Developer][3])
* Update controller connected status and show it in the menu.

**MANUAL CHECK**

* Pair DualSense via Bluetooth.
* Turning controller on/off updates “Controller: Connected/Disconnected”.

---

## Milestone 4 — Read controller state + Debug: show live stick/trigger values in menu

**Implement**

* Prefer DualSense profile `GCDualSenseGamepad`, fallback `GCExtendedGamepad`. ([Apple Developer][2])
* Update `ControllerService.state` in `valueChangedHandler`. ([Apple Developer][9])
* **Critical:** mirror `ControllerService.$state` into `AppModel.@Published debugState` (Combine fix below).

**MANUAL CHECK**

* Open the menu and keep it open.
* Move left stick → values update live.
* Press L2/R2 → trigger values update live.
* Press D-pad/L1/R1 → booleans update live.

---

## Milestone 5 — ActionEngine tick loop (cursor move only)

**Implement**

* Timer (60–120 Hz).
* If Enabled + controller connected:

  * dead zone
  * cursor delta per tick
  * move cursor

**MANUAL CHECK**

* Enabled ON → left stick moves cursor.
* Enabled OFF → cursor stops responding.

---

## Milestone 6 — Clicks, scroll, mouse4/mouse5

**Implement**

* Edge detection (compare previous vs current state).
* Map:

  * R2 threshold → left down/up
  * L2 threshold → right down/up
  * D-pad up/down held → continuous scroll (emit scroll events)
  * L1/R1 edges → other mouse buttons using `.mouseEventButtonNumber` ([Apple Developer][6])
* Scroll event uses `CGEvent` scroll initializer. ([Apple Developer][7])

**MANUAL CHECK**

* R2 left click works.
* L2 right click works.
* D-pad scrolls in a web page.
* L1/R1 work as mouse button 4/5 (browser back/forward if supported).

---

## Milestone 7 — Optional keyboard mapping (after mouse is stable)

**Implement**

* Map one controller button to one key (e.g., “Cross → Space” later).
* Use `CGEvent` keyboard initializer and post. ([Apple Developer][10])

**MANUAL CHECK**

* Press mapped button; verify key appears in TextEdit.

---

# Folder Tree

```
DualSenseMapper/
  DualSenseMapper.xcodeproj
  DualSenseMapper/
    App/
      DualSenseMapperApp.swift
      MenuBarRootView.swift
      DebugControllerView.swift
      AppModel.swift
    Core/
      PermissionService.swift
      ControllerService.swift
      GamepadState.swift
      Mapping.swift
      ActionEngine.swift
    Output/
      MouseInjector.swift
      KeyboardInjector.swift
    Util/
      Math.swift
      KeyCodes.swift
  README.md
```

---

# Starter Swift Files

## App/DualSenseMapperApp.swift

```swift
import SwiftUI

@main
struct DualSenseMapperApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("DualSenseMapper", systemImage: "gamecontroller") {
            MenuBarRootView()
                .environmentObject(model)
        }
    }
}
```

## App/MenuBarRootView.swift

```swift
import SwiftUI

struct MenuBarRootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Enabled", isOn: $model.enabled)
                .onChange(of: model.enabled) { _, newValue in
                    model.setEnabled(newValue)
                }

            Text("Accessibility: \(model.accessibilityStatusText)")
            Text("Controller: \(model.controllerStatusText)")

            Divider()

            // Milestone 4: Live input debug (updates via model.debugState)
            DebugControllerView(state: model.debugState)

            Divider()

            // Milestone 2: manual injection checks (you can remove later)
            Button("Test Mouse Click") { model.testMouseClick() }
            Button("Test Type Enter") { model.testTypeEnter() }

            Divider()

            Button("Quit") { model.quit() }
        }
        .padding(12)
        .frame(width: 320)
    }
}
```

## App/DebugControllerView.swift

```swift
import SwiftUI

struct DebugControllerView: View {
    let state: GamepadState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Debug: Live Controller Values")
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "Left Stick:  x=% .2f  y=% .2f", state.leftX, state.leftY))
                Text(String(format: "Triggers:    L2=% .2f  R2=% .2f", state.l2, state.r2))
                Text("D-Pad:       ↑\(b(state.dpadUp)) ↓\(b(state.dpadDown)) ←\(b(state.dpadLeft)) →\(b(state.dpadRight))")
                Text("Shoulders:   L1 \(b(state.l1))  R1 \(b(state.r1))")
            }
            .font(.system(.body, design: .monospaced))
        }
    }

    private func b(_ v: Bool) -> String { v ? "1" : "0" }
}
```

## App/AppModel.swift  ✅ (includes the debug-state publishing fix)

```swift
import SwiftUI
import AppKit
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var enabled: Bool = false

    // ✅ Published mirrors so SwiftUI updates while menu is open
    @Published private(set) var debugState: GamepadState = .init()
    @Published private(set) var controllerConnected: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private let permission = PermissionService()
    private let controller = ControllerService()
    private let mouse = MouseInjector()
    private let keyboard = KeyboardInjector()
    private lazy var engine = ActionEngine(controller: controller, mouse: mouse, keyboard: keyboard)

    init() {
        controller.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.debugState = newState
            }
            .store(in: &cancellables)

        controller.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                self?.controllerConnected = connected
            }
            .store(in: &cancellables)
    }

    var accessibilityStatusText: String {
        permission.isTrusted ? "Granted" : "Not granted"
    }

    var controllerStatusText: String {
        controllerConnected ? "Connected" : "Disconnected"
    }

    func setEnabled(_ on: Bool) {
        if on {
            // ✅ Must be trusted for event injection to work
            if !permission.ensureTrusted(prompt: true) {
                enabled = false
                engine.stop()
                return
            }
            engine.start()
        } else {
            engine.stop()
        }
    }

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
```

---

## Core/PermissionService.swift

```swift
import Foundation
import ApplicationServices

final class PermissionService {
    var isTrusted: Bool { AXIsProcessTrusted() }

    @discardableResult
    func ensureTrusted(prompt: Bool) -> Bool {
        if AXIsProcessTrusted() { return true }
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options: NSDictionary = [key: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }
}
```

## Core/GamepadState.swift

```swift
import Foundation

struct GamepadState: Equatable {
    var leftX: Float = 0
    var leftY: Float = 0

    var l2: Float = 0
    var r2: Float = 0

    var dpadUp: Bool = false
    var dpadDown: Bool = false
    var dpadLeft: Bool = false
    var dpadRight: Bool = false

    var l1: Bool = false
    var r1: Bool = false

    // Future: DualSense touchpad fields can be added later.
}
```

## Core/ControllerService.swift

```swift
import Foundation
import GameController

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

        // Prefer DualSense profile; fallback to Extended profile.
        if let ds = controller.dualSenseGamepad {
            wireExtendedLikeInputs(ds)
            // Future: wire DualSense touchpad here.
        } else if let eg = controller.extendedGamepad {
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
```

## Core/Mapping.swift

```swift
import Foundation

enum Mapping {
    static let stickDeadZone: Float = 0.15
    static let cursorSpeedPixelsPerSecond: Float = 1600
    static let triggerPressedThreshold: Float = 0.6
    static let scrollSpeedPerTick: Int32 = 20
}
```

## Core/ActionEngine.swift

```swift
import Foundation

@MainActor
final class ActionEngine {
    private let controller: ControllerService
    private let mouse: MouseInjector
    private let keyboard: KeyboardInjector

    private var timer: Timer?
    private var prev = GamepadState()

    private var leftDown = false
    private var rightDown = false

    init(controller: ControllerService, mouse: MouseInjector, keyboard: KeyboardInjector) {
        self.controller = controller
        self.mouse = mouse
        self.keyboard = keyboard
    }

    func start() {
        stop()
        prev = controller.state
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/120.0, repeats: true) { [weak self] _ in
            self?.tick(dt: 1.0/120.0)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil

        if leftDown { mouse.leftUpAtCurrentCursor(); leftDown = false }
        if rightDown { mouse.rightUpAtCurrentCursor(); rightDown = false }
    }

    private func tick(dt: Double) {
        guard controller.isConnected else { return }
        let cur = controller.state

        // Cursor motion from left stick
        let (dx, dy) = stickToCursorDelta(x: cur.leftX, y: cur.leftY, dt: dt)
        if dx != 0 || dy != 0 {
            mouse.moveBy(dx: dx, dy: dy, dragging: leftDown)
        }

        // R2 -> left click down/up
        let r2Pressed = cur.r2 >= Mapping.triggerPressedThreshold
        let r2Prev = prev.r2 >= Mapping.triggerPressedThreshold
        if r2Pressed && !r2Prev { mouse.leftDownAtCurrentCursor(); leftDown = true }
        if !r2Pressed && r2Prev { mouse.leftUpAtCurrentCursor(); leftDown = false }

        // L2 -> right click down/up
        let l2Pressed = cur.l2 >= Mapping.triggerPressedThreshold
        let l2Prev = prev.l2 >= Mapping.triggerPressedThreshold
        if l2Pressed && !l2Prev { mouse.rightDownAtCurrentCursor(); rightDown = true }
        if !l2Pressed && l2Prev { mouse.rightUpAtCurrentCursor(); rightDown = false }

        // D-pad -> scroll
        if cur.dpadUp { mouse.scroll(deltaY: Mapping.scrollSpeedPerTick) }
        if cur.dpadDown { mouse.scroll(deltaY: -Mapping.scrollSpeedPerTick) }

        // L1/R1 -> mouse button 4/5
        if cur.l1 && !prev.l1 { mouse.otherButtonDown(buttonNumber: 3) } // mouse4
        if !cur.l1 && prev.l1 { mouse.otherButtonUp(buttonNumber: 3) }

        if cur.r1 && !prev.r1 { mouse.otherButtonDown(buttonNumber: 4) } // mouse5
        if !cur.r1 && prev.r1 { mouse.otherButtonUp(buttonNumber: 4) }

        prev = cur
    }

    private func stickToCursorDelta(x: Float, y: Float, dt: Double) -> (Int, Int) {
        let (nx, ny) = applyDeadZone(x: x, y: y, deadZone: Mapping.stickDeadZone)
        if nx == 0 && ny == 0 { return (0, 0) }

        let speed = Mapping.cursorSpeedPixelsPerSecond
        let dx = Int(Double(nx * speed) * dt)
        let dy = Int(Double(ny * speed) * dt)
        return (dx, dy)
    }

    private func applyDeadZone(x: Float, y: Float, deadZone: Float) -> (Float, Float) {
        let mag = sqrt(x*x + y*y)
        if mag < deadZone { return (0, 0) }
        let scaled = (mag - deadZone) / (1 - deadZone)
        return ((x / mag) * scaled, (y / mag) * scaled)
    }
}
```

---

## Output/MouseInjector.swift

```swift
import Foundation
import CoreGraphics

final class MouseInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    private func cursor() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    func moveBy(dx: Int, dy: Int, dragging: Bool) {
        var p = cursor()
        p.x += CGFloat(dx)
        p.y += CGFloat(dy)

        let type: CGEventType = dragging ? .leftMouseDragged : .mouseMoved
        guard let ev = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: p, mouseButton: .left) else { return }
        ev.post(tap: .cghidEventTap)
    }

    func leftClickAtCurrentCursor() {
        leftDownAtCurrentCursor()
        leftUpAtCurrentCursor()
    }

    func leftDownAtCurrentCursor()  { button(type: .leftMouseDown, mouseButton: .left) }
    func leftUpAtCurrentCursor()    { button(type: .leftMouseUp, mouseButton: .left) }
    func rightDownAtCurrentCursor() { button(type: .rightMouseDown, mouseButton: .right) }
    func rightUpAtCurrentCursor()   { button(type: .rightMouseUp, mouseButton: .right) }

    private func button(type: CGEventType, mouseButton: CGMouseButton) {
        let p = cursor()
        guard let ev = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: p, mouseButton: mouseButton) else { return }
        ev.post(tap: .cghidEventTap)
    }

    func otherButtonDown(buttonNumber: Int64) { otherButton(down: true, buttonNumber: buttonNumber) }
    func otherButtonUp(buttonNumber: Int64)   { otherButton(down: false, buttonNumber: buttonNumber) }

    private func otherButton(down: Bool, buttonNumber: Int64) {
        let p = cursor()
        let type: CGEventType = down ? .otherMouseDown : .otherMouseUp
        guard let ev = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: p, mouseButton: .center) else { return }
        ev.setIntegerValueField(.mouseEventButtonNumber, value: buttonNumber)
        ev.post(tap: .cghidEventTap)
    }

    func scroll(deltaY: Int32, deltaX: Int32 = 0) {
        guard let ev = CGEvent(scrollWheelEvent2Source: source,
                               units: .pixel,
                               wheelCount: 2,
                               wheel1: deltaY,
                               wheel2: deltaX,
                               wheel3: 0) else { return }
        ev.post(tap: .cghidEventTap)
    }
}
```

## Output/KeyboardInjector.swift

```swift
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
```

---

## Util/Math.swift

```swift
import Foundation
// Placeholder for future smoothing/acceleration curves.
```

## Util/KeyCodes.swift

```swift
import Foundation
// Placeholder for future key tables (Carbon/HIToolbox etc.).
```

---

# README.md

```md
# DualSenseMapper (macOS 15)

Minimal macOS menu bar utility that maps a DualSense controller to mouse/keyboard input.

## What is this?
This is a **menu bar utility**: it shows a persistent icon in the macOS menu bar and displays controls in a small menu when clicked.

## Requirements
- macOS 15 (Sequoia)
- Xcode 16.x

## Build & Run
1. Open `DualSenseMapper.xcodeproj` in Xcode.
2. Select the `DualSenseMapper` scheme and your Mac as run destination.
3. Run (⌘R).
4. The app appears in the menu bar (top of screen).

## Pair DualSense (Bluetooth)
1. Pair the controller in macOS Bluetooth settings.
2. Turn it on.
3. The menu should show **Controller: Connected** after Milestone 3.

## Accessibility Permission (REQUIRED for injection)
This app injects mouse/keyboard using Quartz events (`CGEvent.post(tap:)`). It will not work unless macOS grants Accessibility permission.
1. Click the menu bar icon.
2. Toggle **Enabled** ON.
3. If prompted: System Settings → Privacy & Security → Accessibility → enable DualSenseMapper.
4. Return to the app and toggle Enabled ON again.

## Manual Milestone Checks (these are NOT automated tests)
- Milestone 0: Menu bar appears; Quit works.
- Milestone 1: Enabling prompts for Accessibility; status updates.
- Milestone 2: "Test Mouse Click" and "Test Type Enter" work (after permission).
- Milestone 3: Controller connect/disconnect status updates.
- Milestone 4: Debug section shows live stick/trigger values updating in the menu.
- Milestone 5+: Cursor moves; then clicks/scroll/mouse4/5.
```

---

If you want, once you get Milestone 4 working, I can add an optional debug line showing **thresholded pressed state** for L2/R2 (based on your `Mapping.triggerPressedThreshold`) to make Milestone 6 tuning easier.

[1]: https://developer.apple.com/documentation/swiftui/menubarextra?utm_source=chatgpt.com "MenuBarExtra | Apple Developer Documentation"
[2]: https://developer.apple.com/documentation/gamecontroller/gcdualsensegamepad?utm_source=chatgpt.com "GCDualSenseGamepad | Apple Developer Documentation"
[3]: https://developer.apple.com/documentation/Foundation/NSNotification/Name-swift.struct/GCControllerDidConnect?utm_source=chatgpt.com "GCControllerDidConnect | Apple Developer Documentation"
[4]: https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions?language=objc&utm_source=chatgpt.com "AXIsProcessTrustedWithOptions"
[5]: https://developer.apple.com/documentation/coregraphics/cgevent/init%28mouseeventsource%3Amousetype%3Amousecursorposition%3Amousebutton%3A%29?utm_source=chatgpt.com "init(mouseEventSource:mouseType:mouseCursorPosition: ..."
[6]: https://developer.apple.com/documentation/coregraphics/cgeventfield/mouseeventbuttonnumber?utm_source=chatgpt.com "CGEventField.mouseEventButtonNumber"
[7]: https://developer.apple.com/documentation/coregraphics/cgevent/init%28scrollwheelevent2source%3Aunits%3Awheelcount%3Awheel1%3Awheel2%3Awheel3%3A%29?utm_source=chatgpt.com "init(scrollWheelEvent2Source:units:wheelCount:wheel1: ..."
[8]: https://developer.apple.com/documentation/coregraphics/cgevent/post%28tap%3A%29?utm_source=chatgpt.com "post(tap:) | Apple Developer Documentation"
[9]: https://developer.apple.com/documentation/gamecontroller/gcextendedgamepad/valuechangedhandler?utm_source=chatgpt.com "valueChangedHandler | Apple Developer Documentation"
[10]: https://developer.apple.com/documentation/coregraphics/cgevent/init%28keyboardeventsource%3Avirtualkey%3Akeydown%3A%29?utm_source=chatgpt.com "init(keyboardEventSource:virtualKey:keyDown:)"
