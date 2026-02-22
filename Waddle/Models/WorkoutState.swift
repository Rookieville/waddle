// Live workout state — what ActiveView reads and displays at every tick

import Foundation

// MARK: - WorkoutPhase

/// The state machine for a single workout session.
enum WorkoutPhase {
    case idle       // not yet started, or fully stopped
    case run        // running phase — coral-orange background
    case walk       // walking phase — mint-teal background
    case paused     // user tapped Pause; timer frozen
    case complete   // all cycles finished (limited mode only)
}

// MARK: - WorkoutState

struct WorkoutState {

    // MARK: - Properties

    /// Current phase of the workout.
    var phase: WorkoutPhase = .idle

    /// Seconds remaining in the current phase.
    var timeRemaining: TimeInterval = 30

    /// Which cycle is currently active (1-based). Used for "Round X of Y" display.
    var currentCycle: Int = 1
}
