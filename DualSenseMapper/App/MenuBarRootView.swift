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

            // Debug section (will show zeros until Milestone 4)
            DebugControllerView(state: model.debugState)

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
