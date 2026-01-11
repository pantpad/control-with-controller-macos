import SwiftUI
import AppKit
import Combine

// Milestone 4: Added controller state mirroring to debugState
@MainActor
final class AppModel: ObservableObject {
    /// Bump this when you complete a milestone/feature.
    static let featureVersion = "0.8.0"

    @Published var enabled: Bool = false

    // ✅ Published mirrors so SwiftUI updates while menu is open
    @Published private(set) var debugState: GamepadState = .init()
    @Published private(set) var controllerConnected: Bool = false

    // Step 2: controller diagnostics surfaced in UI
    @Published private(set) var controllerDiagnosticsText: String = ""
    @Published private(set) var controllerLastEventText: String = ""

    // Milestone 8: persisted config (single profile)
    @Published private(set) var config: AppConfig = .default()

    private var cancellables = Set<AnyCancellable>()

    private let configStore = ConfigStore()

    private let permission = PermissionService()
    private let controller = ControllerService()
    private let mouse = MouseInjector()
    private let keyboard = KeyboardInjector()
    private lazy var engine = ActionEngine(controller: controller, mouse: mouse, keyboard: keyboard, config: config)

    init() {
        config = configStore.load()

        // Milestone 4: Mirror controller state to debugState (critical for UI updates)
        controller.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.debugState = newState
            }
            .store(in: &cancellables)

        // Milestone 3: Observe controller connection status
        controller.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                self?.controllerConnected = connected
            }
            .store(in: &cancellables)

        // Step 2: Diagnostics
        controller.$diagnosticsText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.controllerDiagnosticsText = text
            }
            .store(in: &cancellables)

        controller.$lastEventText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.controllerLastEventText = text
            }
            .store(in: &cancellables)
    }

    var versionText: String {
        let short = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
        let build = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
        return "v\(Self.featureVersion) (app \(short) b\(build))"
    }

    var accessibilityStatusText: String {
        permission.isTrusted ? "Granted" : "Not granted"
    }

    var controllerStatusText: String {
        controllerConnected ? "Connected" : "Disconnected"
    }

    func setEnabled(_ on: Bool) {
        if on {
            // Milestone 1: Check permission and prompt if needed
            if !permission.ensureTrusted(prompt: true) {
                // If not granted, force Enabled OFF
                enabled = false
                return
            }
            // Milestone 5: start action engine
            engine.start()
        } else {
            engine.stop()
        }
    }

    // Milestone 2: Test injection methods
    func testMouseClick() {
        guard permission.isTrusted else { return }
        mouse.leftClickAtCurrentCursor()
    }

    func testTypeEnter() {
        guard permission.isTrusted else { return }
        keyboard.tap(.returnKey)
    }

    // Milestone 8: config write helpers (UI will call later)
    func updateConfig(_ newConfig: AppConfig) {
        config = newConfig
        configStore.save(newConfig)
        engine.setConfig(newConfig)
    }

    func resetConfigToDefault() {
        let cfg = configStore.resetToDefault()
        config = cfg
        engine.setConfig(cfg)
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
