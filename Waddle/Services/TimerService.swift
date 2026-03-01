// Drift-resistant tick engine — records phase start date and uses elapsed-time math to avoid accumulated error

import Foundation

// MARK: - TimerService

/// Owns the repeating Timer that drives phase countdowns.
///
/// **Why date math, not tick counting:**
/// A naive implementation subtracts 0.5 on every tick. Over a 30-minute workout
/// that is 3,600 ticks. Each tick fires fractionally late due to RunLoop scheduling.
/// Those tiny errors accumulate. The correct approach records `startDate = Date()`
/// when the phase begins (or resumes) and on every tick computes:
///   `remaining = phaseDuration − Date().timeIntervalSince(startDate)`
/// This is an absolute calculation — drift is impossible.
///
/// **Pause/resume:** `pause()` captures `pausedRemaining` at the moment of pause.
/// `resume()` sets `phaseDuration = pausedRemaining` and resets `startDate = Date()`,
/// so the date math continues from exactly where it left off.
///
/// **RunLoop mode:** The timer is added to `RunLoop.main` with `.common` mode.
/// Without `.common`, the timer silently stops firing while a SwiftUI Picker (or any
/// UIScrollView) tracks a scroll gesture — the RunLoop switches to tracking mode.
///
/// **Thread:** Because the timer runs on `RunLoop.main`, `onTick` is always called on
/// the main thread. `IntervalViewModel` needs no `DispatchQueue.main.async` wrapper.
final class TimerService {

    // MARK: - Callback

    /// Called on every 0.5 s tick and immediately after `start()` / `resume()`.
    /// Delivers the seconds remaining in the current phase.
    /// Always invoked on the main thread.
    var onTick: ((TimeInterval) -> Void)?

    // MARK: - Private State

    private var timer: Timer?

    /// The moment the current phase (or resume) began.
    private var startDate: Date = .init()

    /// Total duration for the current phase.
    /// After a resume, this equals `pausedRemaining` at the time `resume()` was called.
    private var phaseDuration: TimeInterval = 0

    /// Seconds remaining when `pause()` was called. Consumed by `resume()`.
    private var pausedRemaining: TimeInterval = 0

    // MARK: - Public Interface

    /// Begin a new countdown from `duration` seconds.
    ///
    /// Resets all state, schedules the repeating timer, then fires an immediate
    /// tick so the display updates without waiting up to 0.5 s.
    func start(duration: TimeInterval, fireImmediately: Bool = true) {
        stop()                      // invalidate any previous timer before starting fresh
        phaseDuration = duration
        startDate = Date()
        scheduleTimer()
        if fireImmediately {
            onTick?(duration)       // immediate tick — no lag on initial display
        }
    }

    /// Freeze the countdown. Call `resume()` to continue from this exact point.
    func pause() {
        let elapsed = Date().timeIntervalSince(startDate)
        pausedRemaining = max(0, phaseDuration - elapsed)
        cancelTimer()
    }

    /// Continue counting down from where `pause()` left off.
    func resume() {
        guard pausedRemaining > 0 else { return }
        phaseDuration = pausedRemaining
        pausedRemaining = 0
        startDate = Date()
        scheduleTimer()
        onTick?(phaseDuration)      // immediate tick on resume
    }

    /// Stop the timer entirely and reset all internal state.
    func stop() {
        cancelTimer()
        phaseDuration = 0
        pausedRemaining = 0
    }

    // MARK: - Private

    private func scheduleTimer() {
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)   // .common survives UIScrollView tracking mode
        timer = t
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = max(0, phaseDuration - elapsed)
        onTick?(remaining)
    }
}
