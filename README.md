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
