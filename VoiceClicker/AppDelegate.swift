import Cocoa
import Speech
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var clickManager: ClickManager?
    private var voiceRecognizer: VoiceRecognizer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !AXIsProcessTrusted() {
            AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary)
        }
        // マイク権限を要求してから音声認識権限を要求
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            SFSpeechRecognizer.requestAuthorization { [weak self] _ in
                DispatchQueue.main.async { self?.setup() }
            }
        }
    }

    private func setup() {
        let manager = ClickManager()
        clickManager = manager
        statusBarController = StatusBarController(clickManager: manager)
        voiceRecognizer = VoiceRecognizer { manager.performClick() }
    }
}
