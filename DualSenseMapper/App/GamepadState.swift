import Foundation

struct GamepadState: Equatable {
    // Sticks
    var leftX: Float = 0
    var leftY: Float = 0

    var rightX: Float = 0
    var rightY: Float = 0

    // Analog triggers
    var l2: Float = 0
    var r2: Float = 0

    // Face buttons (DualSense names)
    var cross: Bool = false // buttonA
    var circle: Bool = false // buttonB
    var square: Bool = false // buttonX
    var triangle: Bool = false // buttonY

    // D-pad
    var dpadUp: Bool = false
    var dpadDown: Bool = false
    var dpadLeft: Bool = false
    var dpadRight: Bool = false

    // Shoulders
    var l1: Bool = false
    var r1: Bool = false

    // Stick clicks
    var l3: Bool = false
    var r3: Bool = false

    // System buttons (naming depends on controller)
    var options: Bool = false
    var create: Bool = false
}
