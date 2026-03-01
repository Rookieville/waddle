// Active workout screen — full-bleed phase colour, timer, progress, pause/stop controls

import SwiftUI

// MARK: - ActiveView

struct ActiveView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: IntervalViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full-bleed background — cross-fades over 0.6s on each phase transition
            viewModel.phaseColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: viewModel.state.phase)

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
                viewModel.stop()   // navigation is handled inside stop() based on mode
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
            // Phase label ("RUN" / "WALK" / "PAUSED") — driven by live ViewModel state
            PhaseIndicator(phase: viewModel.currentPhase)

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

    /// "Next: Walk 2:00" hint — phase name and duration update on each phase switch.
    private var nextPhasePreview: some View {
        HStack(spacing: 6) {
            Text("Next:")
                .font(.system(.subheadline, design: .default))
                .foregroundStyle(.white.opacity(0.7))

            Text(viewModel.nextPhaseName)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            Text(TimeFormatter.format(viewModel.nextPhaseDuration))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    /// Pause / Resume button centred at the bottom.
    private var bottomControls: some View {
        Button {
            if viewModel.state.phase == .paused {
                viewModel.resume()
            } else {
                viewModel.pause()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.state.phase == .paused ? "play.fill" : "pause.fill")
                Text(viewModel.state.phase == .paused ? "Resume" : "Pause")
            }
            .font(.system(.title3, design: .default).weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(.white.opacity(0.2), in: Capsule())
        }
        .accessibilityLabel(viewModel.state.phase == .paused ? "Resume workout" : "Pause workout")
    }

    // MARK: - Helpers

    /// Progress fraction for the progress bar: 0 = just started, 1 = phase complete.
    private var progressFraction: Double {
        let total = viewModel.state.phase == .walk
            ? viewModel.settings.walkDuration
            : viewModel.settings.runDuration
        guard total > 0 else { return 0 }
        return (total - viewModel.state.timeRemaining) / total
    }
}

// MARK: - Preview

#Preview {
    ActiveView()
        .environmentObject(IntervalViewModel())
}
