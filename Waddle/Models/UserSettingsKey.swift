// String constants for @AppStorage and UserDefaults — prevents key typos across files

import Foundation

// MARK: - UserSettingsKey

enum UserSettingsKey {
    static let countdownEnabled = "countdownEnabled"
    static let voiceEnabled     = "voiceEnabled"
    static let hapticsEnabled   = "hapticsEnabled"
}
