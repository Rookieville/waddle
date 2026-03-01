// Setup screen — pickers for run/walk durations and cycle count, leads to ActiveView

import SwiftUI

// MARK: - SetupView

struct SetupView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: IntervalViewModel

    // MARK: - Local Picker State
    // Duration pickers work in (minutes, seconds) components.
    // We derive and set viewModel.settings.runDuration / walkDuration on change.

    @State private var runMinutes: Int = 0
    @State private var runSeconds: Int = 30
    @State private var walkMinutes: Int = 2
    @State private var walkSeconds: Int = 0

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

                    // Run duration picker
                    DurationPickerRow(
                        label: "Run for",
                        minutes: $runMinutes,
                        seconds: $runSeconds,
                        accentColor: .runColor
                    )
                    .onChange(of: runMinutes) { _, _ in syncRunDuration() }
                    .onChange(of: runSeconds) { _, _ in syncRunDuration() }

                    // Walk duration picker
                    DurationPickerRow(
                        label: "Walk for",
                        minutes: $walkMinutes,
                        seconds: $walkSeconds,
                        accentColor: .walkColor
                    )
                    .onChange(of: walkMinutes) { _, _ in syncWalkDuration() }
                    .onChange(of: walkSeconds) { _, _ in syncWalkDuration() }

                    // Cycles toggle + count
                    cyclesSection

                    // Countdown toggle
                    countdownSection

                    Spacer().frame(height: 8)

                    // Start button
                    startButton
                }
                .padding(.horizontal, DesignSystem.horizontalPadding)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadFromViewModel() }
    }

    // MARK: - Subviews

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

    private var countdownSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Countdown before switch")
                    .font(.system(.body, design: .default).weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                Text(viewModel.settings.countdownEnabled ? "3 … 2 … 1 before each phase" : "No countdown")
                    .font(.system(.footnote, design: .default))
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            Toggle("", isOn: $viewModel.settings.countdownEnabled)
                .labelsHidden()
                .tint(Color.walkColor)
        }
        .padding(DesignSystem.cardPadding)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
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
    }

    // MARK: - Binding Helpers

    /// A Bool binding for the unlimited toggle. When true = unlimited, when false = limited.
    private var unlimitedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.mode == .unlimited },
            set: { viewModel.settings.mode = $0 ? .unlimited : .limited }
        )
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
}
