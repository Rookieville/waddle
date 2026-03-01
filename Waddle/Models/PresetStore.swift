// Manages the ordered list of saved presets — persisted as JSON in UserDefaults

import Foundation

// MARK: - PresetStore

final class PresetStore: ObservableObject {

    // MARK: - Constants

    private static let userDefaultsKey = "savedPresets"

    // MARK: - Published State

    @Published var presets: [Preset] = []

    // MARK: - Init

    init() {
        load()
        if presets.isEmpty { seedDefaults() }
    }

    // MARK: - Public API

    func add(_ preset: Preset) {
        presets.append(preset)
        save()
    }

    func delete(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }

    private func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
            let decoded = try? JSONDecoder().decode([Preset].self, from: data)
        else { return }
        presets = decoded
    }

    // MARK: - Default Presets

    private func seedDefaults() {
        presets = [
            Preset(name: "Beginner",     runDuration: 30,  walkDuration: 120, mode: .unlimited),
            Preset(name: "Intermediate", runDuration: 60,  walkDuration: 60,  mode: .unlimited),
            Preset(name: "Endurance",    runDuration: 120, walkDuration: 30,  mode: .unlimited),
        ]
        save()
    }
}
