// Home screen — entry point, preset selection, and primary CTA

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: IntervalViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.waddleBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // App name
                appNameHeader

                Spacer().frame(height: 48)

                // Heading
                headingSection

                Spacer().frame(height: 40)

                // Preset chips
                presetChipsSection

                Spacer()

                // Primary CTA
                ctaButton
            }
            .padding(.horizontal, DesignSystem.horizontalPadding)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    private var appNameHeader: some View {
        Text("🐧 Waddle")
            .font(.system(.body, design: .default).weight(.semibold))
            .foregroundStyle(Color.textMuted)
    }

    private var headingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Set your\nwaddle pace")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)

            Text("Pick a preset or set your own tempo")
                .font(.system(.body, design: .default))
                .foregroundStyle(Color.textMuted)
        }
    }

    private var presetChipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1
            HStack(spacing: 12) {
                PresetChip(label: "30s / 2m") {
                    applyPreset(run: 30, walk: 120)
                }
                PresetChip(label: "1m / 1m") {
                    applyPreset(run: 60, walk: 60)
                }
            }

            // Row 2
            HStack(spacing: 12) {
                PresetChip(label: "Custom") {
                    viewModel.navigate(to: .setup)
                }
            }
        }
    }

    private var ctaButton: some View {
        Button {
            viewModel.navigate(to: .setup)
        } label: {
            Text("Waddle on →")
                .font(.system(.body, design: .default).weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.runColor, in: RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius))
        }
    }

    // MARK: - Helpers

    private func applyPreset(run: TimeInterval, walk: TimeInterval) {
        viewModel.settings.runDuration = run
        viewModel.settings.walkDuration = walk
        viewModel.navigate(to: .setup)
    }
}

// MARK: - PresetChip

private struct PresetChip: View {

    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(IntervalViewModel())
}
