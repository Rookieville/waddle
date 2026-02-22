// Large all-caps phase label ("RUN" / "WALK") displayed at the centre of ActiveView

import SwiftUI

// MARK: - PhaseIndicator

/// Shows the current workout phase in large, bold, rounded text.
/// Displayed prominently on ActiveView so the user can read it at arm's length.
struct PhaseIndicator: View {

    // MARK: - Properties

    let phase: WorkoutPhase

    // MARK: - Body

    var body: some View {
        Text(label)
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Helpers

    private var label: String {
        switch phase {
        case .run:    return "RUN"
        case .walk:   return "WALK"
        case .paused: return "PAUSED"
        default:      return ""
        }
    }

    private var accessibilityLabel: String {
        switch phase {
        case .run:    return "Running phase"
        case .walk:   return "Walking phase"
        case .paused: return "Workout paused"
        default:      return ""
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.runColor.ignoresSafeArea()
        PhaseIndicator(phase: .run)
    }
}
