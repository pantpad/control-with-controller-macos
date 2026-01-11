import Foundation

struct KeyOption: Identifiable, Hashable {
    let keyCode: UInt16
    let name: String

    var id: UInt16 { keyCode }
}

enum KeyCatalog {
    // US keyboard virtual key codes (hardware positions).
    static let all: [KeyOption] = [
        // Letters
        KeyOption(keyCode: 0x00, name: "A"),
        KeyOption(keyCode: 0x01, name: "S"),
        KeyOption(keyCode: 0x02, name: "D"),
        KeyOption(keyCode: 0x03, name: "F"),
        KeyOption(keyCode: 0x04, name: "H"),
        KeyOption(keyCode: 0x05, name: "G"),
        KeyOption(keyCode: 0x06, name: "Z"),
        KeyOption(keyCode: 0x07, name: "X"),
        KeyOption(keyCode: 0x08, name: "C"),
        KeyOption(keyCode: 0x09, name: "V"),
        KeyOption(keyCode: 0x0B, name: "B"),
        KeyOption(keyCode: 0x0C, name: "Q"),
        KeyOption(keyCode: 0x0D, name: "W"),
        KeyOption(keyCode: 0x0E, name: "E"),
        KeyOption(keyCode: 0x0F, name: "R"),
        KeyOption(keyCode: 0x10, name: "Y"),
        KeyOption(keyCode: 0x11, name: "T"),
        KeyOption(keyCode: 0x12, name: "1"),
        KeyOption(keyCode: 0x13, name: "2"),
        KeyOption(keyCode: 0x14, name: "3"),
        KeyOption(keyCode: 0x15, name: "4"),
        KeyOption(keyCode: 0x16, name: "6"),
        KeyOption(keyCode: 0x17, name: "5"),
        KeyOption(keyCode: 0x18, name: "="),
        KeyOption(keyCode: 0x19, name: "9"),
        KeyOption(keyCode: 0x1A, name: "7"),
        KeyOption(keyCode: 0x1B, name: "-"),
        KeyOption(keyCode: 0x1C, name: "8"),
        KeyOption(keyCode: 0x1D, name: "0"),
        KeyOption(keyCode: 0x1E, name: "]"),
        KeyOption(keyCode: 0x1F, name: "O"),
        KeyOption(keyCode: 0x20, name: "U"),
        KeyOption(keyCode: 0x21, name: "["),
        KeyOption(keyCode: 0x22, name: "I"),
        KeyOption(keyCode: 0x23, name: "P"),
        KeyOption(keyCode: 0x25, name: "L"),
        KeyOption(keyCode: 0x26, name: "J"),
        KeyOption(keyCode: 0x27, name: "'"),
        KeyOption(keyCode: 0x28, name: "K"),
        KeyOption(keyCode: 0x29, name: ";"),
        KeyOption(keyCode: 0x2A, name: "\\"),
        KeyOption(keyCode: 0x2B, name: ","),
        KeyOption(keyCode: 0x2C, name: "/"),
        KeyOption(keyCode: 0x2D, name: "N"),
        KeyOption(keyCode: 0x2E, name: "M"),
        KeyOption(keyCode: 0x2F, name: "."),

        // Common controls
        KeyOption(keyCode: 0x24, name: "Enter"),
        KeyOption(keyCode: 0x4C, name: "Keypad Enter"),
        KeyOption(keyCode: 0x30, name: "Tab"),
        KeyOption(keyCode: 0x31, name: "Space"),
        KeyOption(keyCode: 0x33, name: "Delete"),
        KeyOption(keyCode: 0x35, name: "Escape"),
        KeyOption(keyCode: 0x75, name: "Forward Delete"),

        // Navigation
        KeyOption(keyCode: 0x73, name: "Home"),
        KeyOption(keyCode: 0x77, name: "End"),
        KeyOption(keyCode: 0x74, name: "Page Up"),
        KeyOption(keyCode: 0x79, name: "Page Down"),

        // Arrows
        KeyOption(keyCode: 0x7B, name: "Left Arrow"),
        KeyOption(keyCode: 0x7C, name: "Right Arrow"),
        KeyOption(keyCode: 0x7D, name: "Down Arrow"),
        KeyOption(keyCode: 0x7E, name: "Up Arrow"),

        // Function keys
        KeyOption(keyCode: 0x7A, name: "F1"),
        KeyOption(keyCode: 0x78, name: "F2"),
        KeyOption(keyCode: 0x63, name: "F3"),
        KeyOption(keyCode: 0x76, name: "F4"),
        KeyOption(keyCode: 0x60, name: "F5"),
        KeyOption(keyCode: 0x61, name: "F6"),
        KeyOption(keyCode: 0x62, name: "F7"),
        KeyOption(keyCode: 0x64, name: "F8"),
        KeyOption(keyCode: 0x65, name: "F9"),
        KeyOption(keyCode: 0x6D, name: "F10"),
        KeyOption(keyCode: 0x67, name: "F11"),
        KeyOption(keyCode: 0x6F, name: "F12"),
    ]

    static func name(for keyCode: UInt16) -> String {
        all.first(where: { $0.keyCode == keyCode })?.name ?? String(format: "0x%02X", keyCode)
    }
}
