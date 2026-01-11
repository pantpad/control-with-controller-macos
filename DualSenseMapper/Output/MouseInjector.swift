import Foundation
import CoreGraphics

final class MouseInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    private func cursor() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    private func mainDisplayBounds() -> CGRect {
        CGDisplayBounds(CGMainDisplayID())
    }

    private func clamp(_ point: CGPoint, to bounds: CGRect) -> CGPoint {
        let maxX = bounds.maxX - 1
        let maxY = bounds.maxY - 1

        return CGPoint(
            x: min(max(point.x, bounds.minX), maxX),
            y: min(max(point.y, bounds.minY), maxY)
        )
    }

    func moveBy(dx: Int, dy: Int, dragging: Bool) {
        let current = cursor()
        let intended = CGPoint(x: current.x + CGFloat(dx), y: current.y + CGFloat(dy))
        let p = clamp(intended, to: mainDisplayBounds())

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
