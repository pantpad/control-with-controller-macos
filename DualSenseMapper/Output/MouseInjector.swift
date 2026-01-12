import Foundation
import CoreGraphics

private func displayReconfigurationCallback(display: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags, userInfo: UnsafeMutableRawPointer?) {
    DispatchQueue.global(qos: .userInitiated).async {
        var bounds: [CGRect] = []
        var displayCount: UInt32 = 0
        var displays: [CGDirectDisplayID] = [0, 0, 0, 0]

        let result = CGGetActiveDisplayList(4, &displays, &displayCount)
        if result == .success {
            for i in 0..<Int(displayCount) {
                bounds.append(CGDisplayBounds(displays[i]))
            }
        }

        if bounds.isEmpty {
            bounds.append(CGDisplayBounds(CGMainDisplayID()))
        }

        MouseInjector.updateDisplayBounds(bounds)
    }
}

final class MouseInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    private static var cachedDisplayBounds: [CGRect] = []
    private static let displayBoundsQueue = DispatchQueue(label: "com.dualsensemapper.displaybounds", attributes: .concurrent)

    fileprivate static func updateDisplayBounds(_ bounds: [CGRect]) {
        displayBoundsQueue.async(flags: .barrier) {
            cachedDisplayBounds = bounds
        }
    }

    private var displayBounds: [CGRect] {
        Self.displayBoundsQueue.sync {
            Self.cachedDisplayBounds
        }
    }

    init() {
        refreshDisplayBounds()
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, nil)
    }

    private func refreshDisplayBounds() {
        var bounds: [CGRect] = []
        var displayCount: UInt32 = 0
        var displays: [CGDirectDisplayID] = [0, 0, 0, 0]

        let result = CGGetActiveDisplayList(4, &displays, &displayCount)
        if result == .success {
            for i in 0..<Int(displayCount) {
                bounds.append(CGDisplayBounds(displays[i]))
            }
        }

        if bounds.isEmpty {
            bounds.append(CGDisplayBounds(CGMainDisplayID()))
        }

        Self.updateDisplayBounds(bounds)
    }

    private func cursor() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    private func clampToNearestDisplay(_ point: CGPoint) -> CGPoint {
        var bestPoint = point
        var bestDistance: CGFloat = .infinity

        for bounds in displayBounds {
            let clampedX = min(max(point.x, bounds.minX), bounds.maxX - 1)
            let clampedY = min(max(point.y, bounds.minY), bounds.maxY - 1)
            let clampedPoint = CGPoint(x: clampedX, y: clampedY)

            let dx = point.x - clampedPoint.x
            let dy = point.y - clampedPoint.y
            let distance = dx * dx + dy * dy

            if distance < bestDistance {
                bestDistance = distance
                bestPoint = clampedPoint
            }
        }

        return bestPoint
    }

    func moveBy(dx: Int, dy: Int, dragging: Bool) {
        let current = cursor()
        let intended = CGPoint(x: current.x + CGFloat(dx), y: current.y + CGFloat(dy))
        let p = clampToNearestDisplay(intended)

        let type: CGEventType = dragging ? .leftMouseDragged : .mouseMoved
        guard let ev = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: p, mouseButton: .left) else { return }

        // Important for edge behavior (Dock auto-hide, etc.): keep delta fields set
        // even when the cursor position is clamped.
        ev.setIntegerValueField(.mouseEventDeltaX, value: Int64(dx))
        ev.setIntegerValueField(.mouseEventDeltaY, value: Int64(dy))

        ev.post(tap: .cghidEventTap)
    }

    func leftClickAtCurrentCursor() {
        leftDownAtCurrentCursor()
        leftUpAtCurrentCursor()
    }

    func leftDownAtCurrentCursor()  { button(type: .leftMouseDown, mouseButton: .left) }
    func leftUpAtCurrentCursor()    { button(type: .leftMouseUp, mouseButton: .left) }
    func rightDownAtCurrentCursor() { button(type: .rightMouseDown, mouseButton: .right) }
    func rightUpAtCurrentCursor()   { button(type: .rightMouseUp, mouseButton: .right) }

    private func button(type: CGEventType, mouseButton: CGMouseButton) {
        let p = cursor()
        guard let ev = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: p, mouseButton: mouseButton) else { return }
        ev.post(tap: .cghidEventTap)
    }

    func otherButtonDown(buttonNumber: Int64) { otherButton(down: true, buttonNumber: buttonNumber) }
    func otherButtonUp(buttonNumber: Int64)   { otherButton(down: false, buttonNumber: buttonNumber) }

    private func otherButton(down: Bool, buttonNumber: Int64) {
        let p = cursor()
        let type: CGEventType = down ? .otherMouseDown : .otherMouseUp
        guard let ev = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: p, mouseButton: .center) else { return }
        ev.setIntegerValueField(.mouseEventButtonNumber, value: buttonNumber)
        ev.post(tap: .cghidEventTap)
    }

    func scroll(deltaY: Int32, deltaX: Int32 = 0) {
        guard let ev = CGEvent(scrollWheelEvent2Source: source,
                               units: .pixel,
                               wheelCount: 2,
                               wheel1: deltaY,
                               wheel2: deltaX,
                               wheel3: 0) else { return }
        ev.post(tap: .cghidEventTap)
    }
}
