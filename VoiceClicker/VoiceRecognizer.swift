import Speech
import AVFoundation

class VoiceRecognizer {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()
    private let onTrigger: () -> Void
    private var prevText = ""
    private var running = false

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        start()
    }

    deinit { stop() }

    // MARK: - Start / Stop

    private func start() {
        guard !running else { return }

        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        print("🎙 speech=\(speechStatus.rawValue) mic=\(micStatus.rawValue)")

        guard speechStatus == .authorized else {
            print("⚠️ 音声認識の権限がありません: \(speechStatus.rawValue)")
            return
        }
        guard micStatus == .authorized else {
            print("⚠️ マイクの権限がありません: \(micStatus.rawValue)")
            return
        }
        guard let rec = recognizer, rec.isAvailable else {
            print("⚠️ 音声認識が利用不可")
            return
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req

        task = rec.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.process(result.bestTranscription.formattedString)
                if result.isFinal {
                    self.prevText = ""
                    self.scheduleRestart()
                    return
                }
            }
            if error != nil { self.scheduleRestart() }
        }

        let node = engine.inputNode
        let fmt = node.outputFormat(forBus: 0)

        guard fmt.sampleRate > 0 else {
            print("⚠️ 無効なオーディオフォーマット (sampleRate=0) — 少し待って再試行")
            request?.endAudio()
            request = nil
            task?.cancel()
            task = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.start() }
            return
        }

        node.installTap(onBus: 0, bufferSize: 4096, format: fmt) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        do {
            try engine.start()
            running = true
        } catch {
            print("⚠️ AVAudioEngine エラー: \(error)")
            node.removeTap(onBus: 0)
        }
    }

    private func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        running = false
    }

    private func scheduleRestart() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.start() }
    }

    // MARK: - Detection

    private func process(_ text: String) {
        guard text.count > prevText.count else { return }
        let delta = String(text.dropFirst(prevText.count))
        prevText = text
        if delta.contains("はい") {
            DispatchQueue.main.async { [weak self] in self?.onTrigger() }
        }
    }
}
