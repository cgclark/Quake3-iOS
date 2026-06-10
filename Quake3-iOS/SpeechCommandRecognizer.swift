import Speech
import AVFoundation

// MARK: - Dedicated run-loop thread for SFSpeechRecognizer
//
// SFSpeechRecognizer completion callbacks are dispatched to the GCD main
// queue.  With the CADisplayLink game-loop approach the main queue is free
// between frames, so those callbacks now fire promptly without blocking.
//
// We still create the recognizer on a dedicated thread so that any internal
// run-loop bookkeeping in the framework stays off the main thread.

private final class SpeechLoopThread: Thread {
    var recognizer: SFSpeechRecognizer?
    private(set) var cfRunLoop: CFRunLoop?
    private let ready = DispatchSemaphore(value: 0)

    override func main() {
        RunLoop.current.add(NSMachPort(), forMode: .default)
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        cfRunLoop  = CFRunLoopGetCurrent()
        ready.signal()
        RunLoop.current.run()
    }

    func schedule(_ block: @escaping () -> Void) {
        ready.wait(); ready.signal()
        guard let rl = cfRunLoop else { return }
        CFRunLoopPerformBlock(rl, CFRunLoopMode.defaultMode.rawValue, block)
        CFRunLoopWakeUp(rl)
    }
}

// MARK: - SpeechCommandRecognizer

class SpeechCommandRecognizer {

    static let shared = SpeechCommandRecognizer()

    private var recorder:   AVAudioRecorder?
    private var recordURL:  URL?
    private var isRecording = false
    private var activeTask: SFSpeechRecognitionTask?

    private let speechThread: SpeechLoopThread = {
        let t = SpeechLoopThread()
        t.name = "com.quake3.speech"
        t.qualityOfService = .userInitiated
        t.start()
        return t
    }()

    // Serial queue used only for AVAudioRecorder setup/teardown.
    private let q = DispatchQueue(label: "com.quake3.speech.bg", qos: .userInitiated)

    private init() {}

    // MARK: - Console echo (thread-safe)
    private func qecho(_ msg: String) {
        let cmd = "echo ^3[Voice]^7 \(msg)"
        cmd.withCString { iOS_EnqueueVoiceCommand($0) }
        print("[Voice] \(msg)")
    }

    // MARK: - Permissions
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    // MARK: - C callbacks (game input loop → background queue)
    static let startCallback: @convention(c) () -> Void = {
        SpeechCommandRecognizer.shared.q.async {
            SpeechCommandRecognizer.shared.startRecording()
        }
    }

    static let stopCallback: @convention(c) () -> Void = {
        SpeechCommandRecognizer.shared.q.async {
            SpeechCommandRecognizer.shared.stopAndRecognize()
        }
    }

    // MARK: - Record (on self.q)
    private func startRecording() {
        guard !isRecording else { return }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            qecho("ERROR: not authorized — check Settings > Privacy > Speech Recognition")
            return
        }

        // AVAudioSession must be configured on the main thread.
        DispatchQueue.main.sync {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playAndRecord, mode: .default,
                                     options: [.mixWithOthers, .allowBluetooth])
            try? session.setActive(true)
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("q3voice.m4a")
        recordURL = url

        do {
            recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey:            Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey:          16000,
                AVNumberOfChannelsKey:    1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder?.record()
            isRecording = true
            qecho("recording — release to submit")
        } catch {
            qecho("ERROR: recorder: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop + submit (on self.q — fully async, no semaphore)
    //
    // With CADisplayLink driving the game loop the GCD main queue is free
    // between frames.  The recognitionTask callback fires there promptly,
    // so we no longer need to block self.q waiting for a result.
    private func stopAndRecognize() {
        guard isRecording, let url = recordURL else { return }

        recorder?.stop()
        recorder = nil
        isRecording = false
        qecho("processing...")

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        // Submit from the dedicated speech thread.
        speechThread.schedule { [weak self] in
            guard let self = self else { return }
            self.activeTask = self.speechThread.recognizer?.recognitionTask(
                with: request
            ) { [weak self] result, error in
                // Fires on GCD main queue between CADisplayLink ticks.
                guard let self = self else { return }
                self.activeTask = nil

                if let r = result, r.isFinal {
                    let text = r.bestTranscription.formattedString
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        self.qecho("cmd: \(text)")
                        text.withCString { iOS_EnqueueVoiceCommand($0) }
                    } else {
                        self.qecho("heard nothing")
                    }
                } else if let e = error {
                    self.qecho("err: \(e.localizedDescription)")
                }

                // Clean up temp file — no audio session change needed
                // (.mixWithOthers means SDL audio was unaffected).
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
