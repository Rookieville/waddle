// Converts TimeInterval values into human-readable "M:SS" strings for display

import Foundation

// MARK: - TimeFormatter

enum TimeFormatter {

    /// Format a TimeInterval as "M:SS" — e.g. 90 → "1:30", 30 → "0:30".
    static func format(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format a TimeInterval as "Xm Ys" for DoneView stats — e.g. 1050 → "17m 30s", 45 → "45s".
    static func formatElapsed(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let minutes = total / 60
        let seconds = total % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }
}
