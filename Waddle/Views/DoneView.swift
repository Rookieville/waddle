// Completion screen — shown after a limited-mode workout finishes or the user stops

import SwiftUI

// MARK: - DoneView

struct DoneView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: IntervalViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.waddleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Celebration emoji
                Text("🎉")
                    .font(.system(size: 72))
                    .padding(.bottom, 24)

                // Completion heading
                Text("You waddled! 🐧")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                // Stats row (hardcoded for Milestone 1)
                statsRow

                Spacer()

                // Action buttons
                buttonStack
            }
            .padding(.horizontal, DesignSystem.horizontalPadding)
            .padding(.bottom, 48)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    /// "5 rounds · 17m 30s" summary line.
    private var statsRow: some View {
        Text(statsSummary)
            .font(.system(.body, design: .default))
            .foregroundStyle(Color.textMuted)
    }

    private var buttonStack: some View {
        VStack(spacing: 16) {
            // Go Again — returns to SetupView
            Button {
                viewModel.navigateToRoot()
                viewModel.navigate(to: .setup)
            } label: {
                Text("Go Again →")
                    .font(.system(.body, design: .default).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.runColor, in: RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius))
            }

            // Back to Home — pops all the way to root
            Button {
                viewModel.navigateToRoot()
            } label: {
                Text("Back to Home")
                    .font(.system(.body, design: .default))
                    .foregroundStyle(Color.textMuted)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Helpers

    /// A formatted stats string. Uses hardcoded values for Milestone 1;
    /// replaced with live workout data in Milestone 3.
    private var statsSummary: String {
        let cycles = viewModel.settings.mode == .limited
            ? "\(viewModel.settings.totalCycles) rounds"
            : "Unlimited"
        return "\(cycles)  ·  17m 30s"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DoneView()
    }
    .environmentObject(IntervalViewModel())
}
