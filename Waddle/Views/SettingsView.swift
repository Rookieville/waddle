// Settings screen — app-wide audio toggles and saved presets management

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {

    // MARK: - Environment

    @EnvironmentObject private var presetStore: PresetStore

    // MARK: - Persistent Settings

    @AppStorage(UserSettingsKey.voiceEnabled)     private var voiceEnabled     = true
    @AppStorage(UserSettingsKey.hapticsEnabled)   private var hapticsEnabled   = true
    @AppStorage(UserSettingsKey.countdownEnabled) private var countdownEnabled = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.waddleBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    audioSection
                    presetsSection
                }
                .padding(.horizontal, DesignSystem.horizontalPadding)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Audio & Haptics")

            SettingsToggleRow(
                title: "Voice prompts",
                subtitle: voiceEnabled ? "Run / Walk cues spoken aloud" : "Silent",
                isOn: $voiceEnabled
            )
            SettingsToggleRow(
                title: "Haptics",
                subtitle: hapticsEnabled ? "Vibration on phase change" : "Off",
                isOn: $hapticsEnabled
            )
            SettingsToggleRow(
                title: "Countdown",
                subtitle: countdownEnabled ? "3 … 2 … 1 before each phase" : "No countdown",
                isOn: $countdownEnabled
            )
        }
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Saved Presets")

            if presetStore.presets.isEmpty {
                Text("No saved presets yet. Save one from the setup screen.")
                    .font(.system(.footnote, design: .default))
                    .foregroundStyle(Color.textMuted)
                    .padding(DesignSystem.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
            } else {
                VStack(spacing: 8) {
                    ForEach(presetStore.presets) { preset in
                        presetRow(preset)
                    }
                }
            }
        }
    }

    private func presetRow(_ preset: Preset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.system(.body, design: .default).weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                Text(presetSubtitle(for: preset))
                    .font(.system(.footnote, design: .default))
                    .foregroundStyle(Color.textMuted)
            }
            Spacer()
            Button {
                if let idx = presetStore.presets.firstIndex(of: preset) {
                    presetStore.delete(at: IndexSet(integer: idx))
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(DesignSystem.cardPadding)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.footnote, design: .default).weight(.semibold))
            .foregroundStyle(Color.textMuted)
            .textCase(.uppercase)
    }

    private func presetSubtitle(for preset: Preset) -> String {
        let run  = TimeFormatter.format(preset.runDuration)
        let walk = TimeFormatter.format(preset.walkDuration)
        switch preset.mode {
        case .unlimited: return "\(run) run · \(walk) walk"
        case .limited:   return "\(run) run · \(walk) walk · \(preset.totalCycles) rounds"
        }
    }
}

// MARK: - SettingsToggleRow

struct SettingsToggleRow: View {

    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .default).weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.system(.footnote, design: .default))
                    .foregroundStyle(Color.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.walkColor)
        }
        .padding(DesignSystem.cardPadding)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(PresetStore())
}
