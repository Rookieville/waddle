// Thin linear progress bar showing how far through the current phase the user is

import SwiftUI

// MARK: - CircularTimer

/// Despite the name (retained for spec compliance), this renders a thin linear capsule
/// progress bar — matching the screen layout in the spec. The component can evolve into a
/// circular ring during the Polish milestone if desired.
struct CircularTimer: View {

    // MARK: - Properties

    /// Fraction of the current phase that has elapsed. Range 0…1.
    let progress: Double

    /// The accent colour — should match the current phase colour.
    let color: Color

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 8)

                // Fill
                Capsule()
                    .fill(color.opacity(0.9))
                    .frame(
                        width: geometry.size.width * CGFloat(min(max(progress, 0), 1)),
                        height: 8
                    )
                    .animation(.linear(duration: 0.5), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.runColor.ignoresSafeArea()
        CircularTimer(progress: 0.6, color: .white)
            .padding(.horizontal, 32)
    }
}
