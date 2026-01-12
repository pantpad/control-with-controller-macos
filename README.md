# DualSenseMapper (macOS 15)

Minimal macOS menu bar utility that maps a DualSense controller to mouse/keyboard input. Fully configurable with a visual editor.

## Features
- **Configurable Mappings:** Map any controller button to mouse clicks (left, right, middle, button 4/5) or keyboard keys/combos.
- **Visual Editor:** Interactive DualSense diagram with live button highlights and click-to-select mapping.
- **Smooth Analog Scroll:** Use the right stick for natural vertical scrolling.
- **Modifier Holds:** Map buttons to hold Cmd, Opt, Ctrl, or Shift.
- **Edge-Safe Cursor:** Custom movement logic ensures the Dock and hot corners work correctly.
- **Persistent Settings:** Your mappings are saved automatically.

## Requirements
- macOS 15 (Sequoia)
- Xcode 16.x
- DualSense (PS5) Controller

## Future Work
- [ ] **Refresh-rate-smooth cursor movement** — Currently runs at fixed 120Hz timer, which can look choppy on 240Hz+ displays. Plan: use CVDisplayLink to sync cursor/scroll ticks to the active display's refresh rate, and measure real dt for consistent speed.

## Build & Run (Xcode)
1. Open `DualSenseMapper.xcodeproj` in Xcode.
2. Select the `DualSenseMapper` scheme and your Mac as run destination.
3. Run (⌘R).
4. The app appears in the menu bar (top of screen).

## Build `.app` + install to `/Applications` (recommended for real use)
When running from Xcode, the app path changes frequently (DerivedData). For stable Accessibility permissions + easy launching, install a built `.app` into `/Applications`.

### Option A: Xcode Archive (GUI)
1. Product → Archive
2. Distribute App → Custom → Copy App
3. Move/copy `DualSenseMapper.app` to `/Applications`

### Option B: `xcodebuild` (CLI)
From repo root:
- Build Release:
  - `xcodebuild -project DualSenseMapper.xcodeproj -scheme DualSenseMapper -configuration Release -derivedDataPath build build`
- Install:
  - `ditto "build/Build/Products/Release/DualSenseMapper.app" "/Applications/DualSenseMapper.app"`
- Launch:
  - `open -a "/Applications/DualSenseMapper.app"`

### Updating after code changes
- Rebuild + re-copy to `/Applications` (same commands as above).
- macOS may treat the rebuilt app as “new” for Accessibility.

## Pair DualSense (Bluetooth)
1. Pair the controller in macOS Bluetooth settings.
2. Turn it on.
3. The menu should show **Controller: Connected**.

## Accessibility Permission (REQUIRED for injection)
This app injects mouse/keyboard using Quartz events (`CGEvent.post(tap:)`). It will not work unless macOS grants Accessibility permission.

### First time
1. Click the menu bar icon.
2. Toggle **Enabled** ON.
3. If prompted: System Settings → Privacy & Security → Accessibility → enable DualSenseMapper.
4. Return to the app and toggle Enabled ON again.

### After moving/updating the app
Accessibility permission can be tied to app *path* + code signature. If you rebuild and replace `/Applications/DualSenseMapper.app` and injection stops working:
1. System Settings → Privacy & Security → Accessibility
2. Disable then re-enable `DualSenseMapper` (or remove and add again)
3. Relaunch the app from `/Applications`

## Manual Feature Checks
- **Enable/Disable:** Toggle mapping on/off via the menu.
- **Edit Mappings:** Click "Edit Mappings..." to open the configuration window.
- **Visual Diagram:** Click a button on the controller image to edit its binding.
- **Live Debug:** See real-time controller values in the menu and highlights in the editor.
- **Quit:** Fully exit the application.

---

[1]: https://developer.apple.com/documentation/swiftui/menubarextra "MenuBarExtra | Apple Developer Documentation"
[2]: https://developer.apple.com/documentation/gamecontroller/gcdualsensegamepad "GCDualSenseGamepad | Apple Developer Documentation"
[3]: https://developer.apple.com/documentation/Foundation/NSNotification/Name-swift.struct/GCControllerDidConnect "GCControllerDidConnect | Apple Developer Documentation"
[4]: https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions "AXIsProcessTrustedWithOptions"
[5]: https://developer.apple.com/documentation/coregraphics/cgevent/init%28mouseeventsource%3Amousetype%3Amousecursorposition%3Amousebutton%3A%29 "init(mouseEventSource:mouseType:mouseCursorPosition: ..."
[6]: https://developer.apple.com/documentation/coregraphics/cgeventfield/mouseeventbuttonnumber "CGEventField.mouseEventButtonNumber"
[7]: https://developer.apple.com/documentation/coregraphics/cgevent/init%28scrollwheelevent2source%3Aunits%3Awheelcount%3Awheel1%3Awheel2%3Awheel3%3A%29 "init(scrollWheelEvent2Source:units:wheelCount:wheel1: ..."
[8]: https://developer.apple.com/documentation/coregraphics/cgevent/post%28tap%3A%29 "post(tap:) | Apple Developer Documentation"
[9]: https://developer.apple.com/documentation/gamecontroller/gcextendedgamepad/valuechangedhandler "valueChangedHandler | Apple Developer Documentation"
[10]: https://developer.apple.com/documentation/coregraphics/cgevent/init%28keyboardeventsource%3Avirtualkey%3Akeydown%3A%29 "init(keyboardEventSource:virtualKey:keyDown:)"
