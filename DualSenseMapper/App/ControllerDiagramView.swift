import SwiftUI

struct ControllerDiagramView: View {
    @EnvironmentObject private var model: AppModel

    @Binding var selectedInput: InputID?
    let config: AppConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Controller")
                .font(.headline)

            HStack(alignment: .top, spacing: 24) {
                // Left cluster (D-pad)
                VStack(spacing: 8) {
                    padButton(.dpadUp, label: "↑")
                    HStack(spacing: 8) {
                        padButton(.dpadLeft, label: "←")
                        padButton(.dpadRight, label: "→")
                    }
                    padButton(.dpadDown, label: "↓")
                }

                // Center cluster (PS + touchpad shown, unsupported)
                VStack(spacing: 10) {
                    uiOnlyButton(title: "PS")
                    uiOnlyButton(title: "Touchpad")
                    HStack(spacing: 10) {
                        padButton(.create, label: "Create")
                        padButton(.options, label: "Options")
                    }
                    HStack(spacing: 10) {
                        padButton(.l3, label: "L3")
                        padButton(.r3, label: "R3")
                    }
                }

                // Right cluster (face buttons)
                VStack(spacing: 8) {
                    padButton(.faceNorth, label: "△")
                    HStack(spacing: 8) {
                        padButton(.faceWest, label: "□")
                        padButton(.faceEast, label: "○")
                    }
                    padButton(.faceSouth, label: "✕")
                }
            }

            HStack(spacing: 10) {
                padButton(.l1, label: "L1")
                padButton(.l2, label: "L2")
                Spacer(minLength: 16)
                padButton(.r2, label: "R2")
                padButton(.r1, label: "R1")
            }
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func padButton(_ input: InputID, label: String) -> some View {
        let action = config.bindings[input] ?? .none
        let pressed = isPressed(input)
        let selected = selectedInput == input

        return Button {
            selectedInput = input
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.headline)
                Text(action.shortLabel())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72, height: 52)
            .background(backgroundColor(pressed: pressed, selected: selected))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: selected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func uiOnlyButton(title: String) -> some View {
        return VStack(spacing: 2) {
            Text(title)
                .font(.subheadline)
            Text("Unsupported")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 92, height: 48)
        .background(Color.secondary.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func backgroundColor(pressed: Bool, selected: Bool) -> Color {
        if pressed { return Color.accentColor.opacity(0.25) }
        if selected { return Color.accentColor.opacity(0.12) }
        return Color.secondary.opacity(0.08)
    }

    private func isPressed(_ input: InputID) -> Bool {
        let s = model.debugState
        let threshold = model.config.triggerThreshold

        switch input {
        case .dpadUp: return s.dpadUp
        case .dpadDown: return s.dpadDown
        case .dpadLeft: return s.dpadLeft
        case .dpadRight: return s.dpadRight

        case .faceSouth: return s.cross
        case .faceEast: return s.circle
        case .faceWest: return s.square
        case .faceNorth: return s.triangle

        case .l1: return s.l1
        case .r1: return s.r1

        case .l2: return s.l2 > threshold
        case .r2: return s.r2 > threshold

        case .l3: return s.l3
        case .r3: return s.r3

        case .options: return s.options
        case .create: return s.create
        }
    }
}
