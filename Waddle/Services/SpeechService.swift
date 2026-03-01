// AVAudioEngine-based workout cue player — reliable through the lock screen

import AVFoundation

// MARK: - WorkoutCue

/// Maps each voice coaching moment to its bundled .m4a filename.
enum WorkoutCue: String, CaseIterable {
    case run        = "cue_run"
    case walk       = "cue_walk"
    case three      = "cue_3"
    case two        = "cue_2"
    case one        = "cue_1"
    case lastRound  = "cue_last_round"
    case complete   = "cue_complete"
}

// MARK: - SpeechService

/// Plays pre-recorded .m4a cues via AVAudioEngine + AVAudioPlayerNode.
///
/// WHY AVAUDIOENGINE INSTEAD OF AVAUDIOPLAYER:
/// AVAudioPlayer.play() is silently blocked by iOS when a player wasn't already
/// playing before the screen was locked — even with UIBackgroundModes: audio
/// and an active .playback session. This is an undocumented iOS restriction.
///
/// AVAudioEngine solves this: once the engine is started (at workout begin),
/// it runs as a continuous audio processing graph. Calling
/// playerNode.scheduleBuffer() on a running node is a mixer operation on an
/// already-live graph — not a "new audio start" — so iOS allows it through
/// the lock screen, exactly as it allows the keep-alive loop to continue.
///
/// All .m4a files are decoded to PCM buffers at init time so play() involves
/// zero file I/O in the background.
final class SpeechService {

    // MARK: - Engine Graph

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    // MARK: - Pre-decoded Buffers

    /// PCM audio data decoded from each .m4a at init time.
    /// Eliminates all file I/O from play() — safe to call while locked.
    private var cueBuffers: [WorkoutCue: AVAudioPCMBuffer] = [:]

    // MARK: - State

    /// The cue most recently passed to play(). Used by the scheduleBuffer
    /// completion handler to ignore stale callbacks from superseded cues.
    private var activeCue: WorkoutCue?

    /// True only while the .complete cue is the active cue — guards the
    /// onAllSpeechFinished callback so it fires exactly once, after .complete.
    private var isPlayingCompleteCue = false

    /// Set by IntervalViewModel before play(.complete) to deactivate the audio
    /// session after the cue finishes — so music resumes cleanly post-workout.
    var onAllSpeechFinished: (() -> Void)?

    // MARK: - Init

    init() {
        engine.attach(playerNode)
        loadCueBuffers()
        // Connect using the format of the first loaded buffer so the engine
        // connection format matches what will be scheduled. All cue files are
        // expected to share the same recording format (same session/tool).
        let format = cueBuffers.values.first?.format
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    private func loadCueBuffers() {
        for cue in WorkoutCue.allCases {
            guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "m4a") else {
                print("⚠️ SpeechService: missing file — \(cue.rawValue).m4a")
                continue
            }
            do {
                let file = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(file.length)
                ) else { continue }
                try file.read(into: buffer)
                cueBuffers[cue] = buffer
            } catch {
                print("⚠️ SpeechService: failed to load \(cue.rawValue).m4a — \(error)")
            }
        }
    }

    // MARK: - Engine Lifecycle

    /// Start the audio engine. Must be called after AVAudioSession is activated.
    /// The engine stays running for the entire workout so play() only ever
    /// schedules buffers on an already-live graph.
    func startEngine() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
            playerNode.play()   // arm the node — ready to receive scheduled buffers
        } catch {
            print("⚠️ SpeechService: engine start failed — \(error)")
        }
    }

    /// Stop the engine. Call when the workout ends (after any final cue finishes).
    func stopEngine() {
        activeCue = nil
        isPlayingCompleteCue = false
        playerNode.stop()
        engine.stop()
    }

    // MARK: - Public API

    /// Schedules the given cue for immediate playback on the running engine.
    /// Interrupts any currently playing cue. No-op if the engine is not running.
    func play(_ cue: WorkoutCue) {
        if !engine.isRunning { startEngine() }
        guard engine.isRunning, let buffer = cueBuffers[cue] else {
            print("⚠️ SpeechService: cannot play \(cue.rawValue)")
            return
        }

        // Stop the current buffer and restart the node to cancel any in-flight audio.
        playerNode.stop()
        playerNode.play()

        activeCue = cue
        isPlayingCompleteCue = (cue == .complete)
        let scheduledCue = cue   // captured so the closure can verify it's still current

        playerNode.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.main.async {
                guard let self, self.activeCue == scheduledCue else { return }
                if self.isPlayingCompleteCue {
                    self.isPlayingCompleteCue = false
                    self.onAllSpeechFinished?()
                }
            }
        }
    }
}
