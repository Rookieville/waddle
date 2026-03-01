// Shared ActivityKit attributes — accessed by both the main Waddle target and the WaddleLiveActivity extension.
// IMPORTANT: Add this file to the WaddleLiveActivity target membership via Xcode's File Inspector.

import Foundation
import ActivityKit

// MARK: - WaddleActivityAttributes

struct WaddleActivityAttributes: ActivityAttributes {

    // MARK: - Dynamic State (updated on every tick and phase switch)

    public struct ContentState: Codable, Hashable {
        /// "Run" or "Walk" — the currently active phase.
        var phase: String
        /// Seconds remaining in the current phase, used for display.
        var timeRemaining: Int
        var currentCycle: Int
        /// The configured total cycles. Irrelevant in unlimited mode.
        var totalCycles: Int
        var isUnlimited: Bool
    }

    // MARK: - Static (set once at activity start, never changes)

    /// Workout start timestamp — available if future views need elapsed time.
    var workoutStarted: Date
}
