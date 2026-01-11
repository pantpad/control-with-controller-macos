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
