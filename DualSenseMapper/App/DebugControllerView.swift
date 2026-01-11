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
