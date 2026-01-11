# DualSenseMapper BLUEPRINT

---

## Current Status
- **Version:** v0.8.6
- **Architecture:** Config-driven ActionEngine with SwiftUI MenuBarExtra and dedicated Mappings window.
- **Core Stack:**
  - GameController (GCController)
  - Quartz Events (CGEvent)
  - SwiftUI + Combine
  - UserDefaults (JSON persistence)

---

## Critical Notes
1. **Accessibility Permission:** Required for event injection. Checked via `AXIsProcessTrustedWithOptions`.
2. **State Mirroring:** `AppModel` mirrors `ControllerService.$state` to `@Published debugState` for live UI updates.
3. **Dedicated Window:** The Mappings editor uses a `WindowGroup` instead of a `.sheet` to avoid focus-loss dismissals in `MenuBarExtra`.

---

## Completed Milestones

### Milestone 0–4: Core Foundation
- ✅ App shell with MenuBarExtra.
- ✅ Accessibility permission flow.
- ✅ Controller connection monitoring.
- ✅ Live input debug view.

### Milestone 5: Cursor Movement
- ✅ 120Hz tick loop in `ActionEngine`.
- ✅ Left stick -> Cursor movement with deadzone and speed scaling.
- ✅ Edge-safe movement (clamping + delta injection) for Dock reveal.

### Milestone 6: Basic Output
- ✅ Trigger thresholds for digital actions.
- ✅ Right stick -> Smooth analog scroll.
- ✅ L1/R1 -> Mouse buttons 4/5.

### Milestone 8.0–8.1: Config Core
- ✅ `AppConfig` model with `InputID` and `Action` enums.
- ✅ `ConfigStore` for JSON persistence in `UserDefaults`.
- ✅ `ActionEngine` refactored to be fully config-driven.

### Milestone 8.2–8.3: Config UI
- ✅ Dedicated "Mappings" window via `WindowGroup`.
- ✅ List-based mapping editor with searchable key picker.
- ✅ `ControllerDiagramView`: Visual DualSense representation with live highlights.

### Milestone 8.6: Advanced Mapping
- ✅ `modifiersHold` action: Map a controller button to hold Cmd/Opt/Ctrl/Shift without a specific key.

---

## Future Roadmap

### Milestone 8.4 — Learn Mode (UI Improvement)
- **Goal:** Press a controller button to auto-select it in the editor.
- **Implementation:** Toggle "Learn" in `MappingEditorView`. Listen for state diffs in `debugState` and update `selectedInput`.

### Milestone 8.5 — Record Key (UI Improvement)
- **Goal:** Press a keyboard key/combo to bind it (instead of picking from a list).
- **Implementation:** Add "Record" button. Use `NSEvent` local monitor to capture key code + modifiers.

### Milestone 9: Axis Configuration
- **Goal:** UI for tuning stick sensitivity, deadzones, and scroll speed.
- **Implementation:** Add sliders to Mappings window; store in `AppConfig`.

### Milestone 10: Profiles
- **Goal:** Multiple named mapping profiles.
- **Implementation:** `[Profile]` in config; UI to switch/rename/delete.

---

## Project Structure
```
DualSenseMapper/
  App/
    DualSenseMapperApp.swift      # Entry point, WindowGroup setup
    AppModel.swift                # State management, Combine wiring
    MenuBarRootView.swift         # Menu bar popover UI
    MappingEditorView.swift       # Dedicated mappings window UI
    ControllerDiagramView.swift   # Visual pad representation
    DebugControllerView.swift     # Live values debug section
    KeyCatalog.swift              # Virtual key code table
    ActionLabel.swift             # Action -> String formatting
    GamepadState.swift            # Snapshot of controller inputs
  Core/
    ActionEngine.swift            # The "Heart": integrates input -> output
    AppConfig.swift               # Codable configuration models
    ConfigStore.swift             # Persistence logic (UserDefaults)
    ControllerService.swift       # GameController monitoring
    PermissionService.swift       # Accessibility check logic
    Mapping.swift                 # Hardcoded constants/defaults
  Output/
    MouseInjector.swift           # Quartz mouse event logic
    KeyboardInjector.swift        # Quartz keyboard event logic
```
