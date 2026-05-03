import Cocoa

class ClickManager {
    private(set) var registeredPosition: CGPoint? {
        didSet {
            print("📣 registeredPosition 更新: \(String(describing: registeredPosition))")
            NotificationCenter.default.post(name: .clickPositionChanged, object: registeredPosition)
        }
    }

    func startRecording() {
        OverlayWindowController.shared.show { [weak self] pos in
            print("📍 コールバック呼ばれた pos=\(pos) self=\(String(describing: self))")
            guard let self else {
                print("❌ self が nil — ClickManager が解放されています")
                NSSound(named: "Pop")?.play()
                return
            }
            self.registeredPosition = pos
            NSSound(named: "Pop")?.play()
        }
    }

    // MARK: - Click

    func performClick() {
        guard let pos = registeredPosition else { return }
        let saved = currentCursorCGPoint()
        let src = CGEventSource(stateID: .combinedSessionState)

        CGWarpMouseCursorPosition(pos)
        CGEvent(mouseEventSource: src, mouseType: .leftMouseDown, mouseCursorPosition: pos, mouseButton: .left)?
            .post(tap: .cghidEventTap)
        CGEvent(mouseEventSource: src, mouseType: .leftMouseUp, mouseCursorPosition: pos, mouseButton: .left)?
            .post(tap: .cghidEventTap)
        CGWarpMouseCursorPosition(saved)
    }

    func resetPosition() { registeredPosition = nil }

    // MARK: - Helpers

    private func currentCursorCGPoint() -> CGPoint {
        let ns = NSEvent.mouseLocation
        let h  = NSScreen.screens[0].frame.height
        return CGPoint(x: ns.x, y: h - ns.y)
    }
}

extension Notification.Name {
    static let clickPositionChanged = Notification.Name("VCClickPositionChanged")
}
