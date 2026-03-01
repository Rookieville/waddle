// Setup screen — pickers for run/walk durations and cycle count, leads to ActiveView

import SwiftUI

// MARK: - SetupView

struct SetupView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel:   IntervalViewModel
    @EnvironmentObject private var presetStore: PresetStore

    // MARK: - Local Picker State
    // Duration pickers work in (minutes, seconds) components.
    // We derive and set viewModel.settings.runDuration / walkDuration on change.

    @State private var runMinutes: Int = 0
    @State private var runSeconds: Int = 30
    @State private var walkMinutes: Int = 2
    @State private var walkSeconds: Int = 0

    // MARK: - Save Preset Alert State

    @State private var showSavePresetAlert    = false
    @State private var presetName             = ""
    @State private var showSavedConfirmation  = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.waddleBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // Heading
                    Text("Set your\nwaddle pace")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(4)
                        .padding(.top, 8)

                    // Saved preset chips — quick-apply a saved configuration
                    if !presetStore.presets.isEmpty {
                        presetChipsSection
                    }

                    // Run duration picker
                    DurationPickerRow(
                        label: "Run for",
                        minutes: $runMinutes,
                        seconds: $runSeconds,
                        accentColor: .runColor
                    )
                    .onChange(of: runMinutes) { _, _ in syncRunDuration() }
                    .onChange(of: runSeconds) { _, _ in syncRunDuration() }
                    .accessibilityLabel("Run duration")

                    // Walk duration picker
                    DurationPickerRow(
                        label: "Walk for",
                        minutes: $walkMinutes,
                        seconds: $walkSeconds,
                        accentColor: .walkColor
                    )
                    .onChange(of: walkMinutes) { _, _ in syncWalkDuration() }
                    .onChange(of: walkSeconds) { _, _ in syncWalkDuration() }
                    .accessibilityLabel("Walk duration")

                    // Cycles toggle + count
                    cyclesSection
                        .accessibilityElement(children: .contain)

                    Spacer().frame(height: 8)

                    // Save as Preset (secondary action)
                    savePresetButton

                    // Start button
                    startButton
                }
                .padding(.horizontal, DesignSystem.horizontalPadding)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .top) {
            if showSavedConfirmation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Preset saved!")
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.walkColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: showSavedConfirmation)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadFromViewModel() }
        .alert("Save as Preset", isPresented: $showSavePresetAlert) {
            TextField("Preset name", text: $presetName)
            Button("Save") { savePreset() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Give this configuration a name")
        }
    }

    // MARK: - Subviews

    private var presetChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(presetStore.presets) { preset in
                    Button {
                        applyPreset(preset)
                    } label: {
                        Text(preset.name)
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius))
                    }
                }
            }
        }
    }

    private var cyclesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Toggle row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cycles")
                        .font(.system(.body, design: .default).weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    Text(viewModel.settings.mode == .unlimited ? "Going until you stop" : "Fixed number of rounds")
                        .font(.system(.footnote, design: .default))
                        .foregroundStyle(Color.textMuted)
                }

                Spacer()

                Toggle("", isOn: unlimitedBinding)
                    .labelsHidden()
                    .tint(Color.walkColor)
                    .accessibilityLabel(viewModel.settings.mode == .unlimited ? "Unlimited mode" : "Limited mode, \(viewModel.settings.totalCycles) cycles")
            }
            .padding(DesignSystem.cardPadding)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))

            // Cycle count stepper — only shown in limited mode
            if viewModel.settings.mode == .limited {
                HStack {
                    Text("Rounds")
                        .font(.system(.body, design: .default))
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Stepper(
                        "\(viewModel.settings.totalCycles)",
                        value: $viewModel.settings.totalCycles,
                        in: 1...50
                    )
                    .fixedSize()
                    .foregroundStyle(Color.textPrimary)
                }
                .padding(DesignSystem.cardPadding)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
            }
        }
    }

    private var savePresetButton: some View {
        Button {
            presetName = ""
            showSavePresetAlert = true
        } label: {
            Text("Save as Preset")
                .font(.system(.body, design: .default).weight(.medium))
                .foregroundStyle(Color.runColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius)
                        .stroke(Color.runColor, lineWidth: 1.5)
                )
        }
    }

    private var startButton: some View {
        Button {
            viewModel.start()
            viewModel.navigate(to: .active)
        } label: {
            Text("Start →")
                .font(.system(.body, design: .default).weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.runColor, in: RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius))
        }
        .accessibilityLabel("Start workout")
    }

    // MARK: - Binding Helpers

    /// A Bool binding for the unlimited toggle. When true = unlimited, when false = limited.
    private var unlimitedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.mode == .unlimited },
            set: { viewModel.settings.mode = $0 ? .unlimited : .limited }
        )
    }

    // MARK: - Preset Helpers

    private func applyPreset(_ preset: Preset) {
        viewModel.settings.runDuration  = preset.runDuration
        viewModel.settings.walkDuration = preset.walkDuration
        viewModel.settings.mode         = preset.mode
        viewModel.settings.totalCycles  = preset.totalCycles
        loadFromViewModel()
    }

    private func savePreset() {
        let trimmed = presetName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let preset = Preset(
            name:         trimmed,
            runDuration:  viewModel.settings.runDuration,
            walkDuration: viewModel.settings.walkDuration,
            mode:         viewModel.settings.mode,
            totalCycles:  viewModel.settings.totalCycles
        )
        presetStore.add(preset)
        presetName = ""
        withAnimation { showSavedConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedConfirmation = false }
        }
    }

    // MARK: - Sync Helpers

    private func loadFromViewModel() {
        let run = Int(viewModel.settings.runDuration)
        runMinutes = run / 60
        runSeconds = run % 60

        let walk = Int(viewModel.settings.walkDuration)
        walkMinutes = walk / 60
        walkSeconds = walk % 60
    }

    private func syncRunDuration() {
        viewModel.settings.runDuration = TimeInterval(runMinutes * 60 + runSeconds)
    }

    private func syncWalkDuration() {
        viewModel.settings.walkDuration = TimeInterval(walkMinutes * 60 + walkSeconds)
    }
}

// MARK: - DurationPickerRow

private struct DurationPickerRow: View {

    let label: String
    @Binding var minutes: Int
    @Binding var seconds: Int
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(.body, design: .default).weight(.medium))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 0) {
                // Minutes picker
                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60) { m in
                        Text("\(m)").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Text(":")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(Color.textMuted)

                // Seconds picker
                Picker("Seconds", selection: $seconds) {
                    ForEach(0..<60) { s in
                        Text(String(format: "%02d", s)).tag(s)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 120)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SetupView()
    }
    .environmentObject(IntervalViewModel())
    .environmentObject(PresetStore())
}
