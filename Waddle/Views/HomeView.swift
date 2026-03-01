// Home screen — entry point, preset grid selection, and primary CTA

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel:   IntervalViewModel
    @EnvironmentObject private var presetStore: PresetStore

    // MARK: - State

    /// ID of the currently selected preset. nil = nothing selected (CTA navigates to SetupView).
    @State private var selectedPresetID: UUID? = nil
    /// Whether the grid is in select/delete mode.
    @State private var isSelecting             = false
    /// The preset awaiting delete confirmation — drives the delete alert.
    @State private var presetToDelete: Preset? = nil
    /// Presents SettingsView as a sheet.
    @State private var showSettings            = false

    // MARK: - Grid Layout

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.waddleBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // Fixed heading — never scrolls or gets pushed
                headingSection
                    .padding(.horizontal, DesignSystem.horizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                // Scrollable preset grid — fills all remaining vertical space
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        presetGridContent
                    }
                    .padding(.horizontal, DesignSystem.horizontalPadding)
                    .padding(.vertical, 8)
                }

                // Fixed CTA — pinned outside the ScrollView, always visible
                ctaButton
                    .padding(.horizontal, DesignSystem.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("Waddle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Edit / Done toggle — reveals individual delete buttons on preset cards
                    Button(isSelecting ? "Done" : "Edit") {
                        isSelecting.toggle()
                        if !isSelecting { selectedPresetID = nil }
                    }
                    .foregroundStyle(Color.textMuted)
                    .font(.system(size: 15))

                    // Settings gear
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.textMuted)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
            .environmentObject(presetStore)
        }
        .alert(
            "Delete \"\(presetToDelete?.name ?? "")\"?",
            isPresented: Binding(
                get:  { presetToDelete != nil },
                set:  { if !$0 { presetToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let preset = presetToDelete,
                   let idx = presetStore.presets.firstIndex(where: { $0.id == preset.id }) {
                    if selectedPresetID == preset.id { selectedPresetID = nil }
                    presetStore.delete(at: IndexSet(integer: idx))
                }
                presetToDelete = nil
            }
            Button("Cancel", role: .cancel) { presetToDelete = nil }
        }
        .onAppear {
            selectedPresetID = nil
            isSelecting      = false
        }
    }

    // MARK: - Subviews

    private var headingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set your waddle pace")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Pick a preset or set your own tempo")
                .font(.system(.body, design: .default))
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var presetGridContent: some View {

        // Custom card — always first, immune to select/delete mode
        PresetCardView(
            title:       "Custom",
            subtitle:    "Set your own pace",
            detail:      nil,
            iconName:    "plus",
            isSelected:  false,
            isSelecting: false,
            onTap:       { viewModel.navigate(to: .setup) },
            onDelete:    nil
        )

        // Saved presets (Beginner, Intermediate, Endurance + any user-created)
        ForEach(presetStore.presets) { preset in
            PresetCardView(
                title:       preset.name,
                subtitle:    durationSummary(preset),
                detail:      cycleSummary(preset),
                iconName:    nil,
                isSelected:  selectedPresetID == preset.id,
                isSelecting: isSelecting,
                onTap: {
                    // Card taps only select a preset when not in delete mode
                    if !isSelecting { selectedPresetID = preset.id }
                },
                onDelete: { presetToDelete = preset }
            )
        }
    }

    private var ctaButton: some View {
        Button {
            if let preset = selectedPreset {
                startWithPreset(preset)
            } else {
                viewModel.navigate(to: .setup)
            }
        } label: {
            Text(ctaLabel)
                .font(.system(.body, design: .default).weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.runColor, in: RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius))
        }
        .opacity(selectedPreset == nil ? 0.5 : 1.0)
        .accessibilityLabel(selectedPreset.map { "Start \($0.name) workout" } ?? "Set up and start a workout")
    }

    // MARK: - Helpers

    private var selectedPreset: Preset? {
        presetStore.presets.first { $0.id == selectedPresetID }
    }

    private var ctaLabel: String {
        guard let preset = selectedPreset else { return "Waddle on →" }
        let name      = preset.name
        let truncated = name.count > 12 ? String(name.prefix(12)) + "…" : name
        return "Start \(truncated) →"
    }

    private func startWithPreset(_ preset: Preset) {
        viewModel.settings.runDuration  = preset.runDuration
        viewModel.settings.walkDuration = preset.walkDuration
        viewModel.settings.mode         = preset.mode
        viewModel.settings.totalCycles  = preset.totalCycles
        viewModel.start()
        viewModel.navigate(to: .active)
    }

    private func durationSummary(_ preset: Preset) -> String {
        "\(humanDuration(preset.runDuration)) run · \(humanDuration(preset.walkDuration)) walk"
    }

    private func cycleSummary(_ preset: Preset) -> String {
        preset.mode == .unlimited ? "Unlimited" : "\(preset.totalCycles) rounds"
    }

    private func humanDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let mins  = total / 60
        let secs  = total % 60
        if secs == 0 { return "\(mins) min" }
        return TimeFormatter.format(seconds)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(IntervalViewModel())
    .environmentObject(PresetStore())
}
