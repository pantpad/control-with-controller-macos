import SwiftUI

@main
struct DualSenseMapperApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("DualSenseMapper", systemImage: "gamecontroller") {
            MenuBarRootView()
                .environmentObject(model)
        }
        // `.menu` style often doesn't refresh while open.
        // Use a window-style popover so debug values update live.
        .menuBarExtraStyle(.window)
    }
}
