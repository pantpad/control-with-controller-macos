import Foundation

// Minimal GamepadState for Milestone 0 (just for DebugControllerView)
struct GamepadState: Equatable {
    var leftX: Float = 0
    var leftY: Float = 0
    var l2: Float = 0
    var r2: Float = 0
    var dpadUp: Bool = false
    var dpadDown: Bool = false
    var dpadLeft: Bool = false
    var dpadRight: Bool = false
    var l1: Bool = false
    var r1: Bool = false
}
