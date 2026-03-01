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
                viewModel.stop()
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
            .accessibilityLabel("Stop workout")
        }
    }

    /// Phase label above the circular timer ring.
    private var timerSection: some View {
        VStack(spacing: 24) {
            // Phase label ("RUN" / "WALK" / "PAUSED")
            PhaseIndicator(phase: viewModel.currentPhase)
                .accessibilityLabel(phaseAccessibilityLabel)

            // Circular ring — contains timer digits and next-phase hint inside
            CircularTimer(
                progress: viewModel.progress,
                timeString: TimeFormatter.format(viewModel.state.timeRemaining),
                nextPhaseLabel: nextPhaseLabel,
                isActive: viewModel.state.phase != .paused
            )
            .accessibilityLabel("Time remaining: \(TimeFormatter.format(viewModel.state.timeRemaining))")
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
                    .animation(.easeInOut(duration: 0.3), value: viewModel.state.phase == .paused)
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

    /// Readable VoiceOver label for the current phase.
    private var phaseAccessibilityLabel: String {
        switch viewModel.currentPhase {
        case .run:      return "Current phase: Run"
        case .walk:     return "Current phase: Walk"
        case .paused:   return "Workout paused"
        case .complete: return "Workout complete"
        default:        return "Workout"
        }
    }

    /// Next-phase hint string rendered inside the circular ring.
    private var nextPhaseLabel: String {
        "Next: \(viewModel.nextPhaseName) \(TimeFormatter.format(viewModel.nextPhaseDuration))"
    }
}

// MARK: - Preview

#Preview {
    ActiveView()
        .environmentObject(IntervalViewModel())
}
