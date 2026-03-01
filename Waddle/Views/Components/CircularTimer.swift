// Circular progress ring with timer and next-phase text centred inside

import SwiftUI

// MARK: - CircularTimer

/// A 260×260 circular progress ring that counts DOWN from full to empty
/// as the current phase progresses. Timer digits and the next-phase hint
/// are centred inside the ring so the whole component is self-contained.
///
/// progress: 1.0 = phase just started (ring full), 0.0 = phase ending (ring empty).
struct CircularTimer: View {

    // MARK: - Properties

    /// Remaining fraction of the current phase: 1.0 → 0.0.
    let progress: Double

    /// Formatted time string displayed inside the ring (e.g. "1:30").
    let timeString: String

    /// Next-phase hint displayed below the timer (e.g. "Next: Walk 2:00").
    let nextPhaseLabel: String

    /// True when the timer is actively counting down (not paused).
    /// Drives the subtle scale-down when paused.
    let isActive: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background track — faint white ring
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 8)

            // Progress arc — starts at top (−90°), drains clockwise
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    Color.white.opacity(0.9),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Timer digits + next-phase hint
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)

                Text(nextPhaseLabel)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(width: 260, height: 260)
        // Shrink slightly when paused — gives a visual "at rest" cue
        .scaleEffect(isActive ? 1.0 : 0.97)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.runColor.ignoresSafeArea()
        CircularTimer(
            progress: 0.65,
            timeString: "1:18",
            nextPhaseLabel: "Next: Walk 2:00",
            isActive: true
        )
    }
}
