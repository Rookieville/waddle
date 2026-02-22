// Active workout screen — full-bleed phase colour, timer, progress, pause/stop controls

import SwiftUI

// MARK: - ActiveView

struct ActiveView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: IntervalViewModel

    // MARK: - Local State

    /// Pause state for the static shell — real pause logic is wired in Milestone 2.
    @State private var isPaused = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full-bleed background — colour driven by phase (hardcoded RUN for Milestone 1)
            Color.runColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                timerSection
                Spacer()
                bottomControls
            }
            .padding(.horizontal, DesignSystem.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    /// Cycle counter on the left, stop button on the right.
    private var topBar: some View {
        HStack {
            CycleProgress(
                current: viewModel.state.currentCycle,
                total: viewModel.settings.totalCycles,
                mode: viewModel.settings.mode
            )

            Spacer()

            Button {
                viewModel.stop()
                viewModel.navigate(to: .done)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
                .font(.system(.body, design: .default).weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.2), in: Capsule())
            }
        }
    }

    /// Phase label, timer digits, progress bar, next-phase preview.
    private var timerSection: some View {
        VStack(spacing: 24) {
            // Phase label ("RUN" / "WALK")
            PhaseIndicator(phase: isPaused ? .paused : .run)

            // Timer countdown in large thin rounded digits
            Text(TimeFormatter.format(viewModel.state.timeRemaining))
                .font(.system(size: 96, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            // Linear progress bar
            CircularTimer(progress: progressFraction, color: .white)
                .padding(.horizontal, 8)

            // Next phase preview
            nextPhasePreview
        }
    }

    /// "Next: Walk  2:00" hint shown below the progress bar.
    private var nextPhasePreview: some View {
        HStack(spacing: 6) {
            Text("Next:")
                .font(.system(.subheadline, design: .default))
                .foregroundStyle(.white.opacity(0.7))

            Text("Walk")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            Text(TimeFormatter.format(viewModel.settings.walkDuration))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    /// Pause / Resume button centred at the bottom.
    private var bottomControls: some View {
        Button {
            isPaused.toggle()
            if isPaused {
                viewModel.pause()
            } else {
                viewModel.resume()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                Text(isPaused ? "Resume" : "Pause")
            }
            .font(.system(.title3, design: .default).weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(.white.opacity(0.2), in: Capsule())
        }
        .accessibilityLabel(isPaused ? "Resume workout" : "Pause workout")
    }

    // MARK: - Helpers

    /// Progress fraction for the progress bar: 0 = just started, 1 = phase complete.
    private var progressFraction: Double {
        let total = viewModel.settings.runDuration  // hardcoded to run for Milestone 1
        guard total > 0 else { return 0 }
        let elapsed = total - viewModel.state.timeRemaining
        return elapsed / total
    }
}

// MARK: - Preview

#Preview {
    ActiveView()
        .environmentObject(IntervalViewModel())
}
