// Holds everything the user configures on SetupView before starting a workout

import Foundation

// MARK: - WorkoutSettings

struct WorkoutSettings {

    // MARK: - Properties

    /// Duration of the run phase in seconds. Default: 30 s.
    var runDuration: TimeInterval = 30

    /// Duration of the walk phase in seconds. Default: 2 min.
    var walkDuration: TimeInterval = 120

    /// Whether the workout is unlimited or limited to a fixed cycle count.
    var mode: IntervalMode = .unlimited

    /// Number of run/walk cycles to complete. Only used when mode == .limited.
    var totalCycles: Int = 5

    /// When true, a "3 … 2 … 1" voice countdown fires 3 s before each phase switch.
    var countdownEnabled: Bool = true
}
