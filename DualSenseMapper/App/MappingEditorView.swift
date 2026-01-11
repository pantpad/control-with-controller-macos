import SwiftUI

private enum ActionKind: String, CaseIterable, Identifiable {
    case none

    case mouseLeftHold
    case mouseRightHold
    case mouseMiddleClick
    case mouseButton4
    case mouseButton5

    case keyTap
    case keyHold
    case keyCombo

    var id: String { rawValue }

    var isKeyboard: Bool {
        switch self {
        case .keyTap, .keyHold, .keyCombo: return true
        default: return false
        }
    }

    var label: String {
        switch self {
        case .none: return "None"
        case .mouseLeftHold: return "Mouse: Left Hold"
        case .mouseRightHold: return "Mouse: Right Hold"
        case .mouseMiddleClick: return "Mouse: Middle Click"
        case .mouseButton4: return "Mouse: Button 4"
        case .mouseButton5: return "Mouse: Button 5"
        case .keyTap: return "Key: Tap"
        case .keyHold: return "Key: Hold"
        case .keyCombo: return "Key: Combo"
        }
    }

    init(from action: Action) {
        switch action {
        case .none: self = .none
        case .mouseLeftHold: self = .mouseLeftHold
        case .mouseRightHold: self = .mouseRightHold
        case .mouseMiddleClick: self = .mouseMiddleClick
        case .mouseButton4: self = .mouseButton4
        case .mouseButton5: self = .mouseButton5
        case .keyTap: self = .keyTap
        case .keyHold: self = .keyHold
        case .keyCombo: self = .keyCombo
        }
    }
}

struct MappingEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var draft: AppConfig = .default()
    @State private var selectedInput: InputID? = .faceSouth

    @State private var actionKind: ActionKind = .none
    @State private var keyCode: UInt16 = 0x06 // Z
    @State private var modifiers: Set<KeyModifier> = []

    @State private var keySearch: String = ""


    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(width: 760, height: 520)
        .toolbar { toolbarContent }
        .onAppear {
            draft = model.config
            loadEditorFromDraft()
        }
        .onChange(of: selectedInput) { _, _ in loadEditorFromDraft() }
        .onChange(of: actionKind) { _, _ in applyEditorToDraft() }
        .onChange(of: keyCode) { _, _ in applyEditorToDraft() }
        .onChange(of: modifiers) { _, _ in applyEditorToDraft() }
    }

    private var currentInput: InputID { selectedInput ?? .faceSouth }

    private var sidebar: some View {
        List(selection: $selectedInput) {
            ForEach(InputID.allCases, id: \.self) { input in
                VStack(alignment: .leading, spacing: 2) {
                    Text(input.displayName)
                    Text(actionSummary(draft.bindings[input] ?? .none))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(Optional(input))
            }
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentInput.displayName)
                .font(.title2)

            Picker("Action", selection: $actionKind) {
                ForEach(ActionKind.allCases) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.menu)

            if actionKind.isKeyboard {
                keyEditor
            }

            Spacer()
        }
        .padding(16)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                applyEditorToDraft()
                model.updateConfig(draft)
                dismiss()
            }
        }
        ToolbarItem {
            Button("Reset Defaults") {
                draft = AppConfig.default()
                loadEditorFromDraft()
            }
        }
    }

    private var keyEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Key")
                .font(.headline)

            TextField("Search keys", text: $keySearch)

            List(filteredKeys) { opt in
                HStack {
                    Text(opt.name)
                    Spacer()
                    if opt.keyCode == keyCode {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { keyCode = opt.keyCode }
            }
            .frame(height: 220)

            HStack(spacing: 16) {
                modifierToggle(.command, label: "Cmd")
                modifierToggle(.option, label: "Opt")
                modifierToggle(.control, label: "Ctrl")
                modifierToggle(.shift, label: "Shift")
            }

            Text("Selected: \(KeyCatalog.name(for: keyCode))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var filteredKeys: [KeyOption] {
        if keySearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return KeyCatalog.all
        }
        let q = keySearch.lowercased()
        return KeyCatalog.all.filter { $0.name.lowercased().contains(q) }
    }

    private func modifierToggle(_ mod: KeyModifier, label: String) -> some View {
        Toggle(label, isOn: Binding(
            get: { modifiers.contains(mod) },
            set: { on in
                if on { modifiers.insert(mod) } else { modifiers.remove(mod) }
            }
        ))
        .toggleStyle(.switch)
        .frame(width: 90)
    }

    private func loadEditorFromDraft() {
        let action = draft.bindings[currentInput] ?? .none
        actionKind = ActionKind(from: action)

        switch action {
        case let .keyTap(spec), let .keyHold(spec), let .keyCombo(spec):
            keyCode = spec.keyCode
            modifiers = spec.modifiers
        default:
            // Keep current selection; still allow picking keys before switching kind.
            break
        }
    }

    private func applyEditorToDraft() {
        let newAction: Action

        switch actionKind {
        case .none:
            newAction = .none

        case .mouseLeftHold:
            newAction = .mouseLeftHold
        case .mouseRightHold:
            newAction = .mouseRightHold
        case .mouseMiddleClick:
            newAction = .mouseMiddleClick
        case .mouseButton4:
            newAction = .mouseButton4
        case .mouseButton5:
            newAction = .mouseButton5

        case .keyTap:
            newAction = .keyTap(KeySpec(keyCode: keyCode, modifiers: modifiers))
        case .keyHold:
            newAction = .keyHold(KeySpec(keyCode: keyCode, modifiers: modifiers))
        case .keyCombo:
            newAction = .keyCombo(KeySpec(keyCode: keyCode, modifiers: modifiers))
        }

        if case .none = newAction {
            draft.bindings.removeValue(forKey: currentInput)
        } else {
            draft.bindings[currentInput] = newAction
        }
    }

    private func actionSummary(_ action: Action) -> String {
        switch action {
        case .none:
            return "None"

        case .mouseLeftHold:
            return "Mouse: Left Hold"
        case .mouseRightHold:
            return "Mouse: Right Hold"
        case .mouseMiddleClick:
            return "Mouse: Middle Click"
        case .mouseButton4:
            return "Mouse: Button 4"
        case .mouseButton5:
            return "Mouse: Button 5"

        case let .keyTap(spec):
            return "Key Tap: \(KeyCatalog.name(for: spec.keyCode))\(modsSuffix(spec.modifiers))"
        case let .keyHold(spec):
            return "Key Hold: \(KeyCatalog.name(for: spec.keyCode))\(modsSuffix(spec.modifiers))"
        case let .keyCombo(spec):
            return "Key Combo: \(KeyCatalog.name(for: spec.keyCode))\(modsSuffix(spec.modifiers))"
        }
    }

    private func modsSuffix(_ mods: Set<KeyModifier>) -> String {
        if mods.isEmpty { return "" }

        let ordered: [KeyModifier] = [.command, .option, .control, .shift]
        let parts = ordered.compactMap { m -> String? in
            guard mods.contains(m) else { return nil }
            switch m {
            case .command: return "Cmd"
            case .option: return "Opt"
            case .control: return "Ctrl"
            case .shift: return "Shift"
            }
        }

        return " (" + parts.joined(separator: "+") + ")"
    }
}
