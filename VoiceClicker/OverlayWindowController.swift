import Cocoa

class OverlayWindowController: NSObject {
    static let shared = OverlayWindowController()

    private var window: NSWindow?
    private var onSelect: ((CGPoint) -> Void)?

    func show(onSelect: @escaping (CGPoint) -> Void) {
        self.onSelect = onSelect

        guard let screen = NSScreen.main else { return }
        let win = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        win.level = .screenSaver
        win.backgroundColor = NSColor.black.withAlphaComponent(0.25)
        win.isOpaque = false
        win.ignoresMouseEvents = false
        win.acceptsMouseMovedEvents = false
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let label = NSTextField(labelWithString: "クリックして位置を登録 — Esc でキャンセル")
        label.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.isBezeled = false
        label.drawsBackground = false
        label.sizeToFit()
        label.frame.origin = CGPoint(
            x: (screen.frame.width - label.frame.width) / 2,
            y: screen.frame.height * 0.55
        )

        let view = OverlayView(frame: screen.frame) { [weak self] nsPoint in
            self?.finish(nsPoint: nsPoint)
        }
        view.addSubview(label)
        win.contentView = view

        NSCursor.crosshair.set()
        win.makeKeyAndOrderFront(nil)
        self.window = win

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc
                self?.cancel()
                return nil
            }
            return event
        }
    }

    private func finish(nsPoint: NSPoint) {
        let screenH = NSScreen.screens[0].frame.height
        let cgPoint = CGPoint(x: nsPoint.x, y: screenH - nsPoint.y)
        let callback = onSelect
        close()
        callback?(cgPoint)
    }

    private func cancel() {
        close()
    }

    private func close() {
        NSCursor.arrow.set()
        window?.orderOut(nil)
        window = nil
        onSelect = nil
    }
}

private class OverlayView: NSView {
    private let onClick: (NSPoint) -> Void

    init(frame: NSRect, onClick: @escaping (NSPoint) -> Void) {
        self.onClick = onClick
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func mouseDown(with event: NSEvent) {
        onClick(event.locationInWindow)
    }
}
