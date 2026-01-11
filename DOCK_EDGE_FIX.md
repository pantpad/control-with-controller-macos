# Dock/edge sticky cursor (Milestone 5)

## Symptom
- controller-move cursor hits screen edge; feels stuck; Dock auto-hide never reveal

## Cause (likely)
- injecting absolute `.mouseMoved` events only; at edge position clamps → many events become “same point”
- no `kCGMouseEventDeltaX/Y` set → OS no “continued movement/pressure” into edge
- relying on OS clamp (out-of-bounds points) adds weirdness

## Fix
- clamp to main display bounds before posting
- set `.mouseEventDeltaX/.mouseEventDeltaY` on move event, always (even when clamped)

## Code
- `DualSenseMapper/Output/MouseInjector.swift`
