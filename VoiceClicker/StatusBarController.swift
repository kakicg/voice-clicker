import Cocoa
import ServiceManagement

class StatusBarController {
    private let statusItem: NSStatusItem
    private let clickManager: ClickManager
    private var observer: NSObjectProtocol?

    init(clickManager: ClickManager) {
        self.clickManager = clickManager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "mic.circle.fill", accessibilityDescription: "VoiceClicker")
            btn.image?.isTemplate = true
        }

        rebuildMenu()

        observer = NotificationCenter.default.addObserver(
            forName: .clickPositionChanged, object: nil, queue: .main
        ) { [weak self] _ in self?.rebuildMenu() }
    }

    deinit {
        observer.map { NotificationCenter.default.removeObserver($0) }
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        if let pos = clickManager.registeredPosition {
            menu.addItem(withTitle: "登録位置: (\(Int(pos.x)), \(Int(pos.y)))", action: nil, keyEquivalent: "")
        } else {
            menu.addItem(withTitle: "未登録", action: nil, keyEquivalent: "")
        }

        menu.addItem(.separator())

        let record = NSMenuItem(title: "クリック位置を記録...", action: #selector(startRecording), keyEquivalent: "")
        record.target = self
        menu.addItem(record)

        let reset = NSMenuItem(title: "位置をリセット", action: #selector(resetPosition), keyEquivalent: "r")
        reset.target = self
        menu.addItem(reset)

        menu.addItem(.separator())

        let isEnabled = (try? SMAppService.mainApp.status) == .enabled
        let loginItem = NSMenuItem(
            title: isEnabled ? "ログイン時に起動: オン" : "ログイン時に起動: オフ",
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginItem.target = self
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem.menu = menu
    }

    @objc private func startRecording() { clickManager.startRecording() }
    @objc private func resetPosition() { clickManager.resetPosition() }

    @objc private func toggleLoginItem() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            print("ログイン項目の切り替え失敗: \(error)")
        }
        rebuildMenu()
    }
}
