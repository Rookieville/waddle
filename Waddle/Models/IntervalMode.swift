// Defines whether the workout runs for a fixed number of cycles or indefinitely

import Foundation

// MARK: - IntervalMode

enum IntervalMode: String, Codable {
    case unlimited  // runs until the user taps Stop
    case limited    // runs for a set number of cycles, then completes automatically
}
