import Cocoa

class ClickManager {
    private(set) var registeredPosition: CGPoint? {
        didSet {
            NotificationCenter.default.post(name: .clickPositionChanged, object: registeredPosition)
        }
    }

    // タイムアウト分数。nil = 無効
    var timeoutMinutes: Int? = 30 {
        didSet {
            UserDefaults.standard.set(timeoutMinutes ?? 0, forKey: "timeoutMinutes")
            resetIdleTimer()
        }
    }

    private var idleTimer: Timer?

    init() {
        let saved = UserDefaults.standard.integer(forKey: "timeoutMinutes")
        timeoutMinutes = saved == 0 ? 30 : saved
    }

    // MARK: - Recording

    func startRecording() {
        OverlayWindowController.shared.show { [weak self] pos in
            guard let self else { return }
            self.registeredPosition = pos
            NSSound(named: "Pop")?.play()
            self.resetIdleTimer()
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

        resetIdleTimer()
    }

    func resetPosition() {
        registeredPosition = nil
        idleTimer?.invalidate()
        idleTimer = nil
    }

    // MARK: - Idle Timer

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
        guard let minutes = timeoutMinutes, minutes > 0, registeredPosition != nil else { return }
        idleTimer = Timer.scheduledTimer(withTimeInterval: Double(minutes) * 60, repeats: false) { [weak self] _ in
            self?.registeredPosition = nil
        }
    }

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
