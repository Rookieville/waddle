// Live Activity widget — lock screen banner, Dynamic Island compact / expanded / minimal layouts

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - WaddleLiveActivityLiveActivity

struct WaddleLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WaddleActivityAttributes.self) { context in
            // Lock Screen / StandBy banner
            LockScreenLiveActivityView(state: context.state)
                .activityBackgroundTint(phaseColor(context.state.phase))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded (long-press the Dynamic Island pill)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Text(phaseEmoji(context.state.phase))
                            .font(.system(size: 26))
                        Text(context.state.phase.uppercased())
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(phaseColor(context.state.phase))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(context.state.timeRemaining))
                        .font(.system(.title, design: .rounded).weight(.thin))
                        .monospacedDigit()
                        .foregroundStyle(phaseColor(context.state.phase))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(cycleLabel(context.state))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            } compactLeading: {
                // MARK: Compact leading — phase emoji + label
                HStack(spacing: 3) {
                    Text(phaseEmoji(context.state.phase))
                        .font(.system(size: 13))
                    Text(context.state.phase.uppercased())
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(phaseColor(context.state.phase))
                }

            } compactTrailing: {
                // MARK: Compact trailing — time remaining
                Text(formatTime(context.state.timeRemaining))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(phaseColor(context.state.phase))

            } minimal: {
                // MARK: Minimal — time only (competing Live Activity scenario)
                Text(formatTime(context.state.timeRemaining))
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(phaseColor(context.state.phase))
            }
            .widgetURL(URL(string: "waddle://active"))
            .keylineTint(phaseColor(context.state.phase))
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenLiveActivityView: View {

    let state: WaddleActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 0) {
            // Left: phase icon + label + cycle indicator
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(phaseEmoji(state.phase))
                        .font(.system(size: 28))
                    Text(state.phase.uppercased())
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }
                Text(cycleLabel(state))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            // Right: large timer
            Text(formatTime(state.timeRemaining))
                .font(.system(size: 52, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Helpers

/// Returns the emoji for the given phase string.
private func phaseEmoji(_ phase: String) -> String {
    phase == "Run" ? "🏃" : "🚶"
}

/// Returns the design-token phase colour for the given phase string.
/// Matches runColor (#FF6B35) and walkColor (#4ECDC4) from the main app.
private func phaseColor(_ phase: String) -> Color {
    phase == "Run"
        ? Color(red: 1.0, green: 107 / 255, blue: 53 / 255)
        : Color(red: 78 / 255, green: 205 / 255, blue: 196 / 255)
}

/// Formats seconds into "M:SS" — mirrors TimeFormatter in the main app.
private func formatTime(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return "\(m):\(String(format: "%02d", s))"
}

/// Builds the cycle progress string shown below the phase label.
private func cycleLabel(_ state: WaddleActivityAttributes.ContentState) -> String {
    state.isUnlimited
        ? "Round \(state.currentCycle)"
        : "Round \(state.currentCycle) of \(state.totalCycles)"
}

// MARK: - Preview

private extension WaddleActivityAttributes {
    static var preview: WaddleActivityAttributes {
        WaddleActivityAttributes(workoutStarted: Date())
    }
}

private extension WaddleActivityAttributes.ContentState {
    static var runState: WaddleActivityAttributes.ContentState {
        WaddleActivityAttributes.ContentState(
            phase: "Run", timeRemaining: 28,
            currentCycle: 2, totalCycles: 5, isUnlimited: false
        )
    }
    static var walkState: WaddleActivityAttributes.ContentState {
        WaddleActivityAttributes.ContentState(
            phase: "Walk", timeRemaining: 112,
            currentCycle: 2, totalCycles: 5, isUnlimited: false
        )
    }
}

#Preview("Lock Screen", as: .content, using: WaddleActivityAttributes.preview) {
    WaddleLiveActivityLiveActivity()
} contentStates: {
    WaddleActivityAttributes.ContentState.runState
    WaddleActivityAttributes.ContentState.walkState
}
