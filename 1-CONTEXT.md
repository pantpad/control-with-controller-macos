# macOS 15 “Sequoia” — Build a DualSense → Mouse + Keyboard Utility (Developer Notes)

This document is a **context pack** you can paste into a planning session to design and build your app.

Goal: on macOS 15 Sequoia, let a **Bluetooth-connected DualSense Wireless Controller** act like:
- **Mouse**: move, left/right click, drag, scroll wheel, mouse button 4 & 5
- **Keyboard**: inject chosen key presses when controller buttons are pressed

---

## 0) Two viable implementation strategies (pick one first)

### Strategy A — **Inject events** (recommended for v1)
**DualSense input** → your app → **Quartz event injection** (CGEvent) → system/other apps.

Pros
- Pure user-space app (no system extension).
- Fast to build; no special Apple entitlements.

Cons
- Some apps (especially games) may ignore synthetic events if they read raw HID input.
- You must obtain **Accessibility** permission (TCC).

Core APIs:
- `GameController` framework: controller input, including DualSense profile.
- `CoreGraphics` / Quartz Event Services: `CGEventCreateMouseEvent`, `CGEventCreateScrollWheelEvent`, `CGEventCreateKeyboardEvent`, `CGEventPost`.

References:
- Quartz Event Services / `CGEvent` / `CGEventPost`:  
  https://developer.apple.com/documentation/coregraphics/quartz-event-services  
  https://developer.apple.com/documentation/coregraphics/cgevent/post(tap:)  
  https://developer.apple.com/documentation/coregraphics/cgeventtaplocation/cghideventtap

### Strategy B — **Create a virtual HID mouse/keyboard** (advanced)
**DualSense input** → your app/extension → **virtual HID device** → system sees it as “real hardware”.

Pros
- Works better with apps/games that want “real” devices.
- Cleaner input path: system sees a true mouse/keyboard.

Cons
- Typically requires **special Apple entitlements** and often a **DriverKit system extension**.
- More complex packaging and user approvals.

Two ecosystems to research:
- **CoreHID `HIDVirtualDevice`** (newer Apple API):
  - `HIDVirtualDevice`: https://developer.apple.com/documentation/corehid/hidvirtualdevice
  - “Creating virtual devices”: https://developer.apple.com/documentation/corehid/creatingvirtualdevices
- **DriverKit virtual HID** (example: Karabiner’s VirtualHIDDevice):
  - https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice  
  - Entitlement docs: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.hid.virtual.device  
  - “Requesting Entitlements for DriverKit Development”: https://developer.apple.com/documentation/DriverKit/requesting-entitlements-for-driverkit-development

**Recommendation:** Build Strategy A first. Only move to Strategy B if you hit a hard compatibility wall.

---

## 1) Toolchain for macOS 15 Sequoia

- **Xcode 16.x** supports macOS Sequoia 15.x (Apple’s Xcode support matrix):  
  https://developer.apple.com/support/xcode/
- macOS 15 SDK comes bundled with Xcode 16 (macOS 15 release notes):  
  https://developer.apple.com/documentation/macos-release-notes/macos-15-release-notes

---

## 2) Reading DualSense input on macOS (GameController.framework)

macOS exposes modern controllers via **GameController**:
- Overview: https://developer.apple.com/documentation/gamecontroller/
- DualSense profile: `GCDualSenseGamepad` (available on macOS 11.3+):  
  https://developer.apple.com/documentation/gamecontroller/gcdualsensegamepad

**Connection lifecycle**
- Observe connect/disconnect notifications:
  - `GCController.didConnectNotification`
  - `GCController.didDisconnectNotification`
- Get controllers: `GCController.controllers()`
- Choose a profile:
  - `controller.dualSenseGamepad` (DualSense-specific)
  - `controller.extendedGamepad` (works for most modern pads)

**Input callbacks**
Use the profile’s `valueChangedHandler` to react to button/stick changes (pattern shown in Apple sample code and common practice):
- `GCExtendedGamepad`: https://developer.apple.com/documentation/gamecontroller/gcextendedgamepad
- `GCController`: https://developer.apple.com/documentation/gamecontroller/gccontroller

### Minimal Swift skeleton (controller input)
```swift
import GameController

final class ControllerManager {
    private(set) var controller: GCController?

    func start() {
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

        // Attach immediately if already connected
        GCController.controllers().first.map(attach)
    }

    @objc private func controllerDidConnect(_ note: Notification) {
        guard let c = note.object as? GCController else { return }
        attach(c)
    }

    @objc private func controllerDidDisconnect(_ note: Notification) {
        guard let c = note.object as? GCController else { return }
        if c == controller { controller = nil }
    }

    private func attach(_ c: GCController) {
        controller = c

        // Prefer DualSense profile if available:
        if let ds = c.dualSenseGamepad {
            ds.valueChangedHandler = { gamepad, element in
                // Map element changes to actions
            }
        } else if let eg = c.extendedGamepad {
            eg.valueChangedHandler = { gamepad, element in
                // Map element changes to actions
            }
        }
    }
}
```

### DualSense extras you may want later
`GCDualSenseGamepad` exposes:
- Touchpad (primary/secondary finger), touchpad button  
  e.g. `touchpadPrimary`, `touchpadSecondary`, `touchpadButton`
- Adaptive triggers (`GCDualSenseAdaptiveTrigger`)  
  WWDC talk: “Tap into virtual and physical game controllers” (WWDC21)  
  https://developer.apple.com/videos/play/wwdc2021/10081/

You can ignore these for mouse/keyboard mapping, but the touchpad is a **nice cursor input option**.

---

## 3) Turning controller input into mouse events (Quartz / CoreGraphics)

You’ll use **Quartz Event Services** (`CGEvent`) to synthesize mouse input:
- Quartz Event Services: https://developer.apple.com/documentation/coregraphics/quartz-event-services
- Create mouse events: https://developer.apple.com/documentation/coregraphics/cgevent/init(mouseeventsource:mousetype:mousecursorposition:mousebutton:)
- Post events: https://developer.apple.com/documentation/coregraphics/cgevent/post(tap:)
- Event tap location `cghidEventTap`: https://developer.apple.com/documentation/coregraphics/cgeventtaplocation/cghideventtap
- Scroll events: https://developer.apple.com/documentation/coregraphics/cgeventcreatescrollwheelevent
- Create keyboard events: https://developer.apple.com/documentation/coregraphics/cgevent/init(keyboardeventsource:virtualkey:keydown:)

### 3.1 Mouse move (analog stick → cursor velocity)
Typical approach:
- Apply **dead zone** (e.g. 0.10–0.20).
- Convert stick x/y to a velocity (pixels/sec).
- Update cursor position at a fixed rate (Timer or display link).
- Post `kCGEventMouseMoved` or `kCGEventLeftMouseDragged` when dragging.

Useful notes on coordinates:
- Quartz “global display coordinates” origin is **top-left of the primary display**.
- Cocoa “screen space” origin is **bottom-left**.
  - StackOverflow explanation: https://stackoverflow.com/questions/19884363/
  - Quartz Display Services doc notes upper-left origin for displays:  
    https://leopard-adc.pepas.com/documentation/GraphicsImaging/Conceptual/QuartzDisplayServicesConceptual/QuartzDisplayServicesConceptual.pdf  
  - Apple archived doc “Controlling the Mouse Cursor” mentions global display coordinates and upper-left display origin:  
    https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/QuartzDisplayServicesConceptual/Articles/MouseCursor.html

**Practical tip:** keep everything in **Quartz global coordinates** by reading the current cursor location from a CGEvent:
- `let loc = CGEvent(source: nil)!.location`  (commonly used pattern)

### 3.2 Clicks & drag
- Left click: `kCGEventLeftMouseDown` + `kCGEventLeftMouseUp`
- Right click: `kCGEventRightMouseDown` + `kCGEventRightMouseUp`
- Drag:
  - On button press: `kCGEventLeftMouseDown`
  - While moving: post `kCGEventLeftMouseDragged` events with updated coordinates
  - On release: `kCGEventLeftMouseUp`

Apple docs show `kCGEventLeftMouseDragged` etc in the event types list:
- https://developer.apple.com/documentation/coregraphics/cgeventtype/leftmousedown

### 3.3 Scroll wheel
Use `CGEventCreateScrollWheelEvent`:
- https://developer.apple.com/documentation/coregraphics/cgeventcreatescrollwheelevent
Scroll unit constants:
- `CGScrollEventUnit`: https://developer.apple.com/documentation/coregraphics/cgscrolleventunit

Most apps prefer pixel-based scrolling for smoothness: `kCGScrollEventUnitPixel`.

### 3.4 Mouse button 4 and 5 (and beyond)
Quartz supports up to 32 mouse buttons:
- `CGMouseButton` docs note additional buttons specified in USB order:  
  https://developer.apple.com/documentation/coregraphics/cgmousebutton

To send “other” buttons:
- Event types: `kCGEventOtherMouseDown`, `kCGEventOtherMouseUp` (for buttons 2–31)
- Set the **button number field**:
  - `kCGMouseEventButtonNumber`:  
    https://developer.apple.com/documentation/coregraphics/cgeventfield/mouseeventbuttonnumber

**Typical mapping (USB order)**
- 0: left
- 1: right
- 2: middle
- 3: mouse button 4
- 4: mouse button 5

### 3.5 Swift utility for posting mouse events (example)
```swift
import CoreGraphics

enum MouseButton: Int64 {
    case left = 0, right = 1, middle = 2
    case button4 = 3, button5 = 4
}

final class MouseInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    func move(to point: CGPoint, dragging: Bool = false, button: MouseButton = .left) {
        let type: CGEventType = dragging
            ? (button == .right ? .rightMouseDragged : .leftMouseDragged)
            : .mouseMoved

        guard let ev = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: .left) else { return }
        ev.post(tap: .cghidEventTap)
    }

    func click(_ button: MouseButton, down: Bool, at point: CGPoint) {
        let type: CGEventType
        switch button {
        case .left:  type = down ? .leftMouseDown : .leftMouseUp
        case .right: type = down ? .rightMouseDown : .rightMouseUp
        default:     type = down ? .otherMouseDown : .otherMouseUp
        }

        guard let ev = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: .left) else { return }

        if button.rawValue >= 2 {
            ev.setIntegerValueField(.mouseEventButtonNumber, value: button.rawValue)
        }

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

---

## 4) Turning controller input into keyboard events

Use `CGEventCreateKeyboardEvent`:
- https://developer.apple.com/documentation/coregraphics/cgevent/init(keyboardeventsource:virtualkey:keydown:)

Important: to type a character, you must send **all** needed keystrokes including modifiers (Shift/Option/etc.). This is called out in Apple documentation and frequently repeated in examples:
- Discussion example: https://stackoverflow.com/questions/10734349/simulate-keypress-for-system-wide-hotkeys

### Key codes in Swift
macOS key injection uses **virtual key codes** (`CGKeyCode`).
Common way to reference them is importing Carbon’s HIToolbox constants:
```swift
import Carbon.HIToolbox // for kVK_ANSI_A, kVK_Space, etc.
```

### Swift utility for keyboard injection (example)
```swift
import CoreGraphics
import Carbon.HIToolbox

final class KeyboardInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    func key(_ keyCode: CGKeyCode, down: Bool) {
        guard let ev = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { return }
        ev.post(tap: .cghidEventTap)
    }

    func tap(_ keyCode: CGKeyCode) {
        key(keyCode, down: true)
        key(keyCode, down: false)
    }

    // Example: produce uppercase "Z" by doing SHIFT down + z + SHIFT up.
    func tapShifted(_ keyCode: CGKeyCode) {
        key(CGKeyCode(kVK_Shift), down: true)
        tap(keyCode)
        key(CGKeyCode(kVK_Shift), down: false)
    }
}
```

**Note on layouts:** virtual key codes correspond to physical keys, not characters. If you need “type this Unicode character” robustly across keyboard layouts, you’ll need a keycode/flags lookup using TIS/UCKeyTranslate (more work). For controller mapping (“press X to send Cmd+W”), keycodes are ideal.

---

## 5) Privacy & permissions you must handle (TCC)

### 5.1 Accessibility permission (required for controlling the system)
To inject input into other apps reliably, your process must be a “trusted accessibility client”.

API:
- `AXIsProcessTrustedWithOptions(_:)`:  
  https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions

Typical pattern:
- On first run, call `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])`
- If false, show UI explaining how to enable:
  System Settings → Privacy & Security → Accessibility

Practical guides:
- https://gertrude.app/blog/macos-request-accessibility-control
- https://jano.dev/apple/macos/swift/2025/01/08/Accessibility-Permission.html

### 5.2 Input Monitoring permission (usually NOT needed for this app)
Input Monitoring is for **listening** to keyboard/mouse events from other apps. Your app reads the controller through GameController, so it usually doesn’t need Input Monitoring.

Apple’s user-facing doc:
- https://support.apple.com/guide/mac-help/control-access-to-input-monitoring-on-mac-mchl4cedafb6/mac

### 5.3 App Sandbox caveat
Some developers report that **sandboxed apps may not prompt** for Accessibility permission (or behave inconsistently). If your app is a system-wide input utility, plan to distribute **outside the Mac App Store** and consider disabling App Sandbox.

Discussion threads:
- https://stackoverflow.com/questions/74654210/sandbox-suppressing-accessibility-prompt
- Apple Dev Forums: “Accessibility permission not granted for sandboxed macOS …”  
  https://developer.apple.com/forums/thread/810677

### 5.4 Debug/build path pitfalls
TCC permissions are tied to code signing identity + bundle id + often the app’s path. If Xcode rebuilds into DerivedData with a new path, macOS may “forget” permissions.

Practical reset:
- `tccutil reset Accessibility <your.bundle.id>`
- Macworld overview of using `tccutil` to reset permissions:  
  https://www.macworld.com/article/347452/how-to-fix-macos-accessibility-permission-when-an-app-cant-be-enabled.html

---

## 6) App shape on macOS: menu bar utility + optional “launch at login”

Most controller-to-mouse utilities are best as a **menu bar app**:
- Quick access for enable/disable and profiles.
- Doesn’t need a main window.

SwiftUI approach:
- `MenuBarExtra` (macOS 13+; works on macOS 15)
  - Example tutorial: https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI
  - Another walkthrough: https://sarunw.com/posts/swiftui-menu-bar-app/

### Launch at login
Use `ServiceManagement`’s `SMAppService` (macOS 13+):
- Docs: https://developer.apple.com/documentation/servicemanagement/smappservice

Example snippet:
```swift
import ServiceManagement

func setLaunchAtLogin(_ enabled: Bool) throws {
    if enabled {
        try SMAppService.mainApp.register()
    } else {
        try SMAppService.mainApp.unregister()
    }
}
```

---

## 7) Mapping design (how to keep it maintainable)

### 7.1 Recommended internal model
Separate your code into 4 layers:

1) **Device input**  
   Reads GameController elements and normalizes them into your own events.
   - Example normalized events: `.buttonPressed(.cross)`, `.stick(.left, x:…, y:…)`

2) **Mapping/profile**  
   A data-driven mapping table from inputs to actions.
   - Store as JSON in Application Support
   - Or `Codable` structs in UserDefaults

3) **Action engine**  
   Converts abstract actions into “output primitives”:
   - `moveCursor(dx, dy)`
   - `mouseDown(button)`
   - `scroll(dx, dy)`
   - `keyDown(keycode, flags)`
   - etc.

4) **Injectors**  
   The only layer that touches CGEvent (mouse/keyboard injection).

This separation makes it easy to add:
- Multiple profiles (e.g., “Desktop”, “Browser”, “Game”)
- Per-app auto-switching (if you later add frontmost-app detection)
- On-screen help / configuration UI

### 7.2 A practical default mapping
Here’s a mapping most users expect:

Mouse
- Left stick: cursor move
- R2: left click (or hold for drag)
- L2: right click
- D-pad up/down: scroll vertical
- D-pad left/right: scroll horizontal (optional)
- L1 / R1: mouse button 4 / 5
- Touchpad: cursor move (optional, often best)
- Touchpad click: middle click

Keyboard
- Options / Create buttons: send Escape / Enter
- Face buttons: WASD or arrow keys (if you want a “keyboard mode”)
- PS button: toggle your utility on/off (be careful: system may reserve it sometimes)

---

## 8) Open-source projects worth reading (code references)

These projects solve similar problems (controller → keyboard/mouse) and are great references for architecture and UX:

- **Enjoyable** (classic macOS joystick mapper):  
  https://github.com/shirosaki/enjoyable  
  Also see: https://yukkurigames.com/enjoyable/

- **Enjoy2** (simpler fork with analog-to-mouse & scrolling):  
  https://github.com/fyhuang/enjoy2

- **GamepadMenu** (maps gamepad to keyboard; menu bar style):  
  https://github.com/robbertkl/GamepadMenu

- **JoyMapperSilicon** (modern Apple Silicon era mapper; keyboard + mouse):  
  https://github.com/qibinc/JoyMapperSilicon

- **Barrier** (Synergy-like app; good CoreGraphics event injection examples):  
  https://github.com/debauchee/barrier/blob/master/src/lib/platform/OSXScreen.mm

- **Karabiner-DriverKit-VirtualHIDDevice** (virtual keyboard/mouse via DriverKit):  
  https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice

---

## 9) Notes specific to DualSense hardware

macOS supports DualSense via GameController (macOS 11.3+). Apple lists DualSense in Game Controller docs, and DualSense profile availability states macOS 11.3+.

Key references:
- DualSense profile availability:  
  https://developer.apple.com/documentation/gamecontroller/gcdualsensegamepad?language=objc
- Sony pairing instructions (end-user):  
  https://www.playstation.com/en-us/support/hardware/pair-dualsense-controller-bluetooth/

If you later want advanced output features (adaptive triggers/haptics over USB), you may end up in HID report land (e.g., HIDAPI), but **you do not need that** for keyboard/mouse mapping:
- HIDAPI: https://github.com/libusb/hidapi

---

## 10) A concrete build checklist (Strategy A)

### Phase 1 — Prototype (hardcode a mapping)
- [ ] Create a macOS app (SwiftUI or AppKit).
- [ ] Implement controller connect/disconnect and read left stick + a few buttons.
- [ ] Implement `MouseInjector` (move/click/scroll) via CGEvent.
- [ ] Implement `KeyboardInjector` via CGEvent.
- [ ] Add a simple enable/disable toggle in a menu bar UI.
- [ ] Add Accessibility permission check + instructions screen.

### Phase 2 — Make it usable
- [ ] Add sensitivity, acceleration, dead zone settings.
- [ ] Add profile system (`Codable` profiles stored on disk).
- [ ] Add UI to edit mappings.
- [ ] Add “hold trigger to drag” logic.
- [ ] Add mouse button 4/5 mapping and confirm with browsers/file manager.

### Phase 3 — Polish & distribution
- [ ] Proper code signing.
- [ ] Ensure TCC permission flow works from a stable location (/Applications).
- [ ] Optional: launch-at-login via `SMAppService`.
- [ ] Optional: per-app profile switching.

---

## 11) When Strategy A won’t be enough (and what to do)

If you discover a target app/game ignores synthetic events, you likely need a **virtual HID** approach:
- CoreHID `HIDVirtualDevice` (user-space API, but likely entitlement-gated).
- DriverKit Virtual HID system extension (heavyweight; entitlement + approvals).

Start by reading:
- `HIDVirtualDevice` and “Creating virtual devices”:  
  https://developer.apple.com/documentation/corehid/hidvirtualdevice  
  https://developer.apple.com/documentation/corehid/creatingvirtualdevices
- Entitlement:  
  https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.hid.virtual.device
- DriverKit entitlement request workflow:  
  https://developer.apple.com/documentation/DriverKit/requesting-entitlements-for-driverkit-development
- Karabiner VirtualHIDDevice as a working reference:  
  https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice

---

## 12) What to paste into your planning prompt

If you want a short “build intent” paragraph for your next planning step, use this:

> Build a macOS 15 Sequoia menu bar utility in Swift/SwiftUI. Read DualSense input via GameController (prefer GCDualSenseGamepad, fallback to GCExtendedGamepad). Convert controller elements into a normalized input stream, apply a profile-based mapping to mouse/keyboard actions, and inject system-wide input using CoreGraphics Quartz Event Services (CGEventCreateMouseEvent/CGEventCreateScrollWheelEvent/CGEventCreateKeyboardEvent and CGEventPost at .cghidEventTap). Require Accessibility permission using AXIsProcessTrustedWithOptions with prompt, and provide a user flow to enable it. Support cursor motion with dead zones + adjustable sensitivity, click/drag logic, scrolling, and extra mouse buttons (4/5) via .otherMouseDown/.otherMouseUp with .mouseEventButtonNumber. Add launch-at-login with SMAppService. Keep injectors isolated from mapping logic to allow multiple profiles and later upgrades to a virtual HID device approach if needed.

---

*End of context pack.*
