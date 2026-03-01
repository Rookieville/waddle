// A single saved preset — Codable value type persisted via PresetStore

import Foundation

// MARK: - Preset

struct Preset: Identifiable, Codable, Hashable {

    var id: UUID
    var name: String
    var runDuration: TimeInterval   // seconds
    var walkDuration: TimeInterval  // seconds
    var mode: IntervalMode
    var totalCycles: Int

    init(
        id: UUID = UUID(),
        name: String,
        runDuration: TimeInterval,
        walkDuration: TimeInterval,
        mode: IntervalMode = .unlimited,
        totalCycles: Int = 5
    ) {
        self.id           = id
        self.name         = name
        self.runDuration  = runDuration
        self.walkDuration = walkDuration
        self.mode         = mode
        self.totalCycles  = totalCycles
    }
}
