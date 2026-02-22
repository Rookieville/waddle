// "Round X of Y" or "Going until you stop" label shown at the top of ActiveView

import SwiftUI

// MARK: - CycleProgress

/// Displays the current cycle position in limited mode, or the unlimited-mode badge.
struct CycleProgress: View {

    // MARK: - Properties

    let current: Int
    let total: Int
    let mode: IntervalMode

    // MARK: - Body

    var body: some View {
        Text(label)
            .font(.system(.title3, design: .rounded).weight(.medium))
            .foregroundStyle(.white.opacity(0.85))
            .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Helpers

    private var label: String {
        switch mode {
        case .limited:
            return "Round \(current) of \(total)"
        case .unlimited:
            return "Going until you stop"
        }
    }

    private var accessibilityLabel: String {
        switch mode {
        case .limited:
            return "Round \(current) of \(total)"
        case .unlimited:
            return "Unlimited mode — going until you stop"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.runColor.ignoresSafeArea()
        VStack(spacing: 16) {
            CycleProgress(current: 2, total: 5, mode: .limited)
            CycleProgress(current: 1, total: 1, mode: .unlimited)
        }
    }
}
