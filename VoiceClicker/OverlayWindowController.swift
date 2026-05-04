import Cocoa

class OverlayWindowController: NSObject {
    static let shared = OverlayWindowController()

    private var windows: [NSWindow] = []
    private var onSelect: ((CGPoint) -> Void)?

    func show(onSelect: @escaping (CGPoint) -> Void) {
        self.onSelect = onSelect

        let primaryH = NSScreen.screens[0].frame.height

        for screen in NSScreen.screens {
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

            // ウィンドウ内クリック座標 → CGEvent座標（左上原点）へ変換
            // nsPoint はウィンドウ座標系（画面左下原点）なので
            // グローバルNS座標 = screen.frame.origin + nsPoint
            // CG座標 = (globalNS.x, primaryH - globalNS.y)
            let screenOrigin = screen.frame.origin
            let view = OverlayView(frame: screen.frame) { [weak self] nsPoint in
                let globalNS = CGPoint(x: screenOrigin.x + nsPoint.x,
                                      y: screenOrigin.y + nsPoint.y)
                let cgPoint = CGPoint(x: globalNS.x, y: primaryH - globalNS.y)
                self?.finish(cgPoint: cgPoint)
            }
            view.addSubview(label)
            win.contentView = view
            win.makeKeyAndOrderFront(nil)
            windows.append(win)
        }

        NSCursor.crosshair.set()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc
                self?.close()
                return nil
            }
            return event
        }
    }

    private func finish(cgPoint: CGPoint) {
        let callback = onSelect
        close()
        callback?(cgPoint)
    }

    private func close() {
        NSCursor.arrow.set()
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
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
