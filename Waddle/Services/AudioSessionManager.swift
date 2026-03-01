// AVAudioSession configuration, pipeline keep-alive, and interruption recovery — Milestones 4 & 5

import AVFoundation

// MARK: - AudioSessionManager

/// Configures AVAudioSession for the workout lifecycle and keeps the audio pipeline
/// continuously alive so AVSpeechSynthesizer fires reliably through the lock screen.
///
/// WHY A LOOPING SILENT PLAYER:
/// iOS keeps an app's audio background privilege only while audio is ACTUALLY PLAYING
/// through the session. A merely "active" session without real audio output gets quietly
/// reclaimed by the system seconds after backgrounding. AVSpeechSynthesizer then has no
/// live pipeline to speak through and produces silence — no error, no delegate callback.
/// Playing an inaudible (volume 0) looping clip for the workout's duration guarantees
/// the pipeline stays live at all times, so every synthesizer utterance fires correctly.
///
/// Session lifecycle:
///   Workout starts  → activate()   — setCategory, setActive(true), start keep-alive loop
///   Each utterance  → .duckOthers auto-ducks music while synthesizer speaks
///   Interruption    → handleInterruption() re-arms session + restarts keep-alive loop
///   Workout stops   → deactivate() — stop keep-alive loop, setActive(false)
final class AudioSessionManager {

    // MARK: - Private State

    /// Inaudible looping player — the sole mechanism that keeps the audio pipeline alive.
    private var keepAlivePlayer: AVAudioPlayer?

    /// Guards the interruption handler: only re-arm if the workout is still active.
    private var isSessionActive = false

    /// Token returned by NotificationCenter — held so we can remove the observer in deinit.
    private var interruptionObserver: NSObjectProtocol?

    // MARK: - Init / Deinit

    init() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    deinit {
        if let obs = interruptionObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Session Lifecycle

    /// Call once on workout Start, before the first SpeechService.speak() call.
    /// Sets the audio session category, marks it active, and begins the keep-alive loop.
    func activate() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default,
                                    options: [.duckOthers, .mixWithOthers, .allowBluetoothA2DP])
            try session.setActive(true)
            isSessionActive = true
        } catch {
            print("AudioSessionManager: activate failed — \(error)")
            return
        }
        startKeepAliveLoop()
    }

    /// Call once on workout Stop (user-initiated or auto-complete).
    /// Stops the keep-alive loop, then deactivates the session so music resumes.
    func deactivate() {
        isSessionActive = false
        keepAlivePlayer?.stop()
        keepAlivePlayer = nil
        do {
            try AVAudioSession.sharedInstance()
                .setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("AudioSessionManager: deactivate failed — \(error)")
        }
    }

    // MARK: - Keep-Alive Loop

    private func startKeepAliveLoop() {
        let wavData = makeSilentWAVData()
        // AVFileType.wav.rawValue = "com.microsoft.waveform-audio" — required for correct UTI
        guard let player = try? AVAudioPlayer(data: wavData,
                                              fileTypeHint: AVFileType.wav.rawValue) else {
            print("AudioSessionManager: keep-alive player init failed")
            return
        }
        player.volume = 0               // fully inaudible — purpose is pipeline maintenance only
        player.numberOfLoops = -1       // loop indefinitely until deactivate() stops it
        player.prepareToPlay()
        player.play()
        keepAlivePlayer = player
    }

    // MARK: - Interruption Recovery

    /// Re-arms the session and restarts the keep-alive loop after a phone call, Siri,
    /// alarm, or other audio interruption ends. Without this, all subsequent voice
    /// prompts are silent for the rest of the workout.
    private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue),
            type == .ended,
            isSessionActive
        else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default,
                                    options: [.duckOthers, .mixWithOthers, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("AudioSessionManager: interruption recovery failed — \(error)")
            return
        }
        startKeepAliveLoop()
    }

    // MARK: - WAV Generation

    /// Builds a minimal valid WAV: 44-byte header + ~0.3 s of 16-bit mono silence (zero PCM).
    /// Generated in-memory — no bundle resource required, no .pbxproj changes.
    private func makeSilentWAVData() -> Data {
        // Nested helper: append any FixedWidthInteger as little-endian bytes.
        // Using Data(bytes:count:) avoids any ambiguity with Data's own withUnsafeBytes.
        func le<T: FixedWidthInteger>(_ d: inout Data, _ v: T) {
            var val = v.littleEndian
            d.append(Data(bytes: &val, count: MemoryLayout<T>.size))
        }

        let sampleRate:    Int32 = 44100
        let numChannels:   Int16 = 1
        let bitsPerSample: Int16 = 16
        let numSamples = Int(sampleRate) / 3       // ~0.33 s — long enough to avoid clip boundaries
        let dataSize   = Int32(numSamples * 2)     // 16-bit mono

        var d = Data()
        d.append(contentsOf: "RIFF".utf8)
        le(&d, Int32(36 + dataSize))               // ChunkSize
        d.append(contentsOf: "WAVE".utf8)
        d.append(contentsOf: "fmt ".utf8)
        le(&d, Int32(16))                          // Subchunk1Size (PCM)
        le(&d, Int16(1))                           // AudioFormat = PCM
        le(&d, numChannels)
        le(&d, sampleRate)
        le(&d, sampleRate * 2)                     // ByteRate
        le(&d, Int16(2))                           // BlockAlign
        le(&d, bitsPerSample)
        d.append(contentsOf: "data".utf8)
        le(&d, dataSize)
        d.append(contentsOf: [UInt8](repeating: 0, count: Int(dataSize)))
        return d
    }
}
