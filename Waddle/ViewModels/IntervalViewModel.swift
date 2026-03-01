// The brain of the app — single source of truth for all workout state and navigation

import SwiftUI
import Combine
import UIKit
import ActivityKit

// MARK: - AppRoute

/// All destinations in the app's navigation stack.
/// Using an enum + NavigationPath lets the ViewModel control navigation programmatically
/// — Views never push/pop directly, they call ViewModel methods. Pure MVVM.
enum AppRoute: Hashable {
    case setup
    case active
    case done
}

// MARK: - IntervalViewModel

final class IntervalViewModel: ObservableObject {

    // MARK: - Navigation State

    /// NavigationPath is SwiftUI's type-erased stack. The WaddleApp NavigationStack is bound
    /// to this path, so appending/removing routes here drives all screen transitions.
    @Published var navigationPath = NavigationPath()

    // MARK: - Workout Settings (SetupView binds to these)

    @Published var settings = WorkoutSettings()

    // MARK: - Live Workout State (ActiveView reads these)

    @Published var state = WorkoutState()
    @Published var isRunning = false

    /// Full duration of the current phase — used to calculate progress for the circular ring.
    /// Updated at the start of each phase so the ring starts full and counts down to empty.
    @Published var totalPhaseDuration: TimeInterval = 0

    // MARK: - Services (owned by ViewModel)

    private let timerService = TimerService()
    private let speechService = SpeechService()
    private let audioSessionManager = AudioSessionManager()

    // MARK: - Private Phase Tracking

    /// The phase that was active when pause() was called; restored on resume().
    private var phaseBeforePause: WorkoutPhase = .run

    /// Running total of active workout time — accumulated as phases complete.
    private var totalElapsedTime: TimeInterval = 0

    /// Tracks which countdown second ("3", "2", "1") has already been spoken in
    /// the current phase. Prevents duplicate speech on the 0.5-s tick boundary.
    /// Reset to 0 at the start of each new phase in switchPhase().
    private var lastCountdownSpoken: Int = 0

    // MARK: - Background Lifecycle State

    /// The moment the app entered the background. nil when in the foreground.
    private var backgroundedAt: Date?

    /// `state.timeRemaining` captured at the instant of backgrounding.
    private var remainingAtBackground: TimeInterval = 0

    /// `state.phase` captured at the instant of backgrounding (.run or .walk).
    private var phaseAtBackground: WorkoutPhase = .run

    /// `state.currentCycle` captured at the instant of backgrounding.
    private var cycleAtBackground: Int = 1

    // MARK: - Live Activity

    private var activity: Activity<WaddleActivityAttributes>?

    // MARK: - Init

    init() {
        timerService.onTick = { [weak self] remaining in
            self?.handleTick(remaining)
        }
        setupLifecycleObservers()
    }

    // MARK: - Background Lifecycle

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        // Only snapshot during an active run or walk phase.
        // Paused, complete, and idle states have no running timer to reconcile.
        // Limiting to .run/.walk also prevents the foreground loop from entering
        // an infinite spin if phase is .complete (default: break never advances remaining).
        guard isRunning, state.phase == .run || state.phase == .walk else { return }
        backgroundedAt = Date()
        remainingAtBackground = state.timeRemaining
        phaseAtBackground = state.phase
        cycleAtBackground = state.currentCycle
    }

    @objc private func appWillEnterForeground() {
        guard isRunning,
              state.phase != .paused,
              let bg = backgroundedAt else { return }

        let elapsed = Date().timeIntervalSince(bg)
        backgroundedAt = nil   // consume immediately before any early return

        var remaining = remainingAtBackground - elapsed
        var phase     = phaseAtBackground
        var cycle     = cycleAtBackground

        // Fast-forward through any phase crossings that occurred while backgrounded.
        // `remaining` is negative when a phase has expired; adding the next phase
        // duration carries the overshoot correctly into the new phase.
        while remaining <= 0 {
            switch phase {
            case .run:
                remaining += settings.walkDuration
                phase = .walk

            case .walk:
                if settings.mode == .limited && cycle >= settings.totalCycles {
                    // Workout completed while backgrounded — mirror switchPhase() logic
                    state.phase = .complete
                    state.currentCycle = cycle
                    timerService.stop()
                    speechService.onAllSpeechFinished = { [weak self] in
                        self?.speechService.stopEngine()
                        self?.audioSessionManager.deactivate()
                        self?.speechService.onAllSpeechFinished = nil
                    }
                    playVoiceCue(.complete)
                    navigate(to: .done)
                    return
                }
                cycle += 1
                remaining += settings.runDuration
                phase = .run

            default:
                break
            }
        }

        // Apply reconciled state to the @Published properties ActiveView observes
        state.phase         = phase
        state.currentCycle  = cycle
        state.timeRemaining = remaining
        totalPhaseDuration  = phase == .run ? settings.runDuration : settings.walkDuration
        lastCountdownSpoken = 0   // prevent stale suppression for the new phase position

        // Resync timer from the reconciled remaining — resets startDate to now.
        // fireImmediately:false avoids an immediate tick that could call switchPhase()
        // if remaining < 1.0; state.timeRemaining is already set above so display
        // is correct without waiting for the first natural tick.
        timerService.start(duration: remaining, fireImmediately: false)
        updateLiveActivity()
    }

    // MARK: - Navigation Helpers

    /// Push a new screen onto the navigation stack.
    func navigate(to route: AppRoute) {
        navigationPath.append(route)
    }

    /// Pop all screens — returns to HomeView.
    func navigateToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }

    // MARK: - Workout Actions

    func start() {
        totalElapsedTime = 0
        lastCountdownSpoken = 0
        isRunning = true
        state.phase = .run
        state.currentCycle = 1
        // Activate audio session before speaking — ensures music ducking is in
        // place before the first utterance fires, avoiding a race condition.
        totalPhaseDuration = settings.runDuration
        audioSessionManager.activate()
        speechService.startEngine()   // engine must start after session is active
        triggerHaptic(.heavy)
        playVoiceCue(.run)
        timerService.start(duration: settings.runDuration)
        // TimerService fires an immediate tick → state.timeRemaining updates at once
        startLiveActivity()
    }

    func pause() {
        phaseBeforePause = state.phase   // preserve whether we were in .run or .walk
        state.phase = .paused
        timerService.pause()
    }

    func resume() {
        state.phase = phaseBeforePause
        timerService.resume()
    }

    func stop() {
        // Accumulate elapsed time for the partial phase we're stopping in
        let activePhase = state.phase == .paused ? phaseBeforePause : state.phase
        totalElapsedTime += max(0, phaseDuration(for: activePhase) - state.timeRemaining)

        // Stop audio immediately (user-initiated stop — no cue to wait for)
        speechService.stopEngine()
        timerService.stop()
        audioSessionManager.deactivate()
        endLiveActivity()
        isRunning = false
        state.phase = .idle
        state.timeRemaining = settings.runDuration
        // state.currentCycle is intentionally NOT reset here — DoneView reads it

        // Navigation is mode-dependent; ViewModel owns this decision
        if settings.mode == .limited {
            navigate(to: .done)
        } else {
            state.currentCycle = 1
            navigateToRoot()
        }
    }

    // MARK: - Timer Handling

    private func handleTick(_ remaining: TimeInterval) {
        state.timeRemaining = max(0, remaining)
        updateLiveActivity()

        if remaining < 1.0 {    // switch on the first tick that would display "0:00"
            switchPhase()
            return
        }

        // Countdown: play "3", "2", "1" once each in the 3 seconds before phase end.
        // Int(remaining) floors to a whole-second bucket — e.g. 3.5 → 3, 2.9 → 2.
        // lastCountdownSpoken prevents the 0.5-s tick from playing the same cue twice.
        if UserDefaults.standard.bool(forKey: UserSettingsKey.countdownEnabled) {
            let second = Int(remaining)
            if second >= 1 && second <= 3 && second != lastCountdownSpoken {
                lastCountdownSpoken = second
                let cue: WorkoutCue
                switch second {
                case 3: cue = .three
                case 2: cue = .two
                default: cue = .one
                }
                triggerHaptic(.light)
                playVoiceCue(cue)
            }
        }
    }

    // MARK: - State Machine

    /// Transitions to the next phase when the current phase timer reaches zero.
    private func switchPhase() {
        switch state.phase {
        case .run:
            // Run complete → start Walk
            totalElapsedTime += settings.runDuration
            lastCountdownSpoken = 0
            state.phase = .walk
            state.timeRemaining = settings.walkDuration         // flip display instantly
            totalPhaseDuration = settings.walkDuration
            triggerHaptic(.medium)
            playVoiceCue(.walk)
            timerService.start(duration: settings.walkDuration,
                               fireImmediately: false)          // let scheduled ticks drive it
            updateLiveActivity()

        case .walk:
            // Walk complete → check for cycle completion
            totalElapsedTime += settings.walkDuration
            lastCountdownSpoken = 0

            if settings.mode == .limited && state.currentCycle >= settings.totalCycles {
                // All cycles done — auto-complete
                state.phase = .complete
                timerService.stop()
                if UserDefaults.standard.bool(forKey: UserSettingsKey.hapticsEnabled) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                // Deactivate the audio session only after the complete cue finishes
                // playing — so music resumes cleanly after the cue, not mid-play.
                speechService.onAllSpeechFinished = { [weak self] in
                    self?.speechService.stopEngine()
                    self?.audioSessionManager.deactivate()
                    self?.speechService.onAllSpeechFinished = nil
                }
                playVoiceCue(.complete)
                endLiveActivity()
                navigate(to: .done)
            } else {
                // Continue to the next cycle
                state.currentCycle += 1
                state.phase = .run
                state.timeRemaining = settings.runDuration      // flip display instantly
                totalPhaseDuration = settings.runDuration
                triggerHaptic(.heavy)
                // "Last round!" plays first; "Run" follows after 0.8 s so it doesn't
                // immediately cut off the previous cue (AVAudioPlayer doesn't queue).
                if settings.mode == .limited && state.currentCycle == settings.totalCycles {
                    playVoiceCue(.lastRound)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                        self?.playVoiceCue(.run)
                    }
                } else {
                    playVoiceCue(.run)
                }
                timerService.start(duration: settings.runDuration,
                                   fireImmediately: false)      // let scheduled ticks drive it
                updateLiveActivity()
            }

        default:
            break
        }
    }

    // MARK: - Live Activity Actions

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = WaddleActivityAttributes(workoutStarted: Date())
        let initialState = WaddleActivityAttributes.ContentState(
            phase: "Run",
            timeRemaining: Int(settings.runDuration),
            currentCycle: 1,
            totalCycles: settings.totalCycles,
            isUnlimited: settings.mode == .unlimited
        )
        do {
            let content = ActivityContent(state: initialState, staleDate: nil)
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("⚠️ IntervalViewModel: Live Activity failed to start — \(error)")
        }
    }

    private func updateLiveActivity() {
        let activePhase = state.phase == .paused ? phaseBeforePause : state.phase
        let phaseString: String
        switch activePhase {
        case .run:  phaseString = "Run"
        case .walk: phaseString = "Walk"
        default:    return  // only update during active run/walk phases
        }
        let updatedState = WaddleActivityAttributes.ContentState(
            phase: phaseString,
            timeRemaining: Int(state.timeRemaining),
            currentCycle: state.currentCycle,
            totalCycles: settings.totalCycles,
            isUnlimited: settings.mode == .unlimited
        )
        Task {
            await activity?.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
            activity = nil
        }
    }

    // MARK: - Private Helpers

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard UserDefaults.standard.bool(forKey: UserSettingsKey.hapticsEnabled) else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    private func playVoiceCue(_ cue: WorkoutCue) {
        guard UserDefaults.standard.bool(forKey: UserSettingsKey.voiceEnabled) else { return }
        speechService.play(cue)
    }

    private func phaseDuration(for phase: WorkoutPhase) -> TimeInterval {
        switch phase {
        case .run:  return settings.runDuration
        case .walk: return settings.walkDuration
        default:    return 0
        }
    }

    // MARK: - Convenience Computed Properties

    var currentPhase: WorkoutPhase { state.phase }
    var timeRemaining: TimeInterval { state.timeRemaining }
    var currentCycle: Int { state.currentCycle }

    /// Total active workout time accumulated so far — used by DoneView stats.
    var elapsedTime: TimeInterval { totalElapsedTime }

    /// Background colour for ActiveView — holds the pre-pause colour when paused.
    var phaseColor: Color {
        let active = state.phase == .paused ? phaseBeforePause : state.phase
        return active == .walk ? .walkColor : .runColor
    }

    /// Label for the upcoming phase shown in ActiveView's "Next:" preview.
    var nextPhaseName: String {
        let active = state.phase == .paused ? phaseBeforePause : state.phase
        return active == .run ? "Walk" : "Run"
    }

    /// Duration of the upcoming phase shown in ActiveView's "Next:" preview.
    var nextPhaseDuration: TimeInterval {
        let active = state.phase == .paused ? phaseBeforePause : state.phase
        return active == .run ? settings.walkDuration : settings.runDuration
    }

    /// Fraction of the current phase remaining — 1.0 at phase start, 0.0 at phase end.
    /// Drives the circular progress ring countdown in ActiveView.
    var progress: Double {
        guard totalPhaseDuration > 0 else { return 0 }
        return state.timeRemaining / totalPhaseDuration
    }
}
