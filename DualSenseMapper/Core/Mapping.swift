import Foundation

enum Mapping {
    static let stickDeadZone: Float = 0.15
    static let cursorSpeedPixelsPerSecond: Float = 1600

    static let triggerDownThreshold: Float = 0.60

    static let scrollRepeatHz: Double = 30
    static let scrollDeltaPixels: Int32 = 40

    // USB button numbering (Quartz): 3=button4, 4=button5
    static let mouseButton4Number: Int64 = 3
    static let mouseButton5Number: Int64 = 4
}
