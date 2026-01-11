import SwiftUI
import AppKit

struct MenuBarRootView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Enabled", isOn: $model.enabled)
                .onChange(of: model.enabled) { _, newValue in
                    model.setEnabled(newValue)
                }

            Text("Version: \(model.versionText)")
            Text("Accessibility: \(model.accessibilityStatusText)")
            Text("Controller: \(model.controllerStatusText)")

            Divider()

            // Debug section (will show zeros until Milestone 4)
            DebugControllerView(state: model.debugState)

            Divider()

            Text("Diagnostics")
                .font(.headline)
            Text(model.controllerDiagnosticsText)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
            Text("Last event: \(model.controllerLastEventText)")
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)

            Divider()

            // Milestone 8.2: mapping editor (dedicated window, not sheet)
            Button("Edit Mappings…") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "mappings")
            }
            Divider()

            // Milestone 2: manual injection checks
            Button("Test Mouse Click") { model.testMouseClick() }
            Button("Test Type Enter") { model.testTypeEnter() }

            Divider()

            Button("Quit") { model.quit() }
        }
        .padding(12)
        .frame(width: 320)
    }
}
