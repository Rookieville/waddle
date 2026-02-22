// The brain of the app — single source of truth for all workout state and navigation

import SwiftUI
import Combine

// MARK: - AppRoute

/// All destinations in the app's navigation stack.
/// Using an enum + NavigationPath lets the ViewModel control navigation programmatically
/// — Views never push/pop directly, they call ViewModel methods. Pure MVVM.
enum AppRoute: Hashable {
    case setup
    case active
    case done
}

// MARK: - IntervalViewModel

final class IntervalViewModel: ObservableObject {

    // MARK: - Navigation State

    /// NavigationPath is SwiftUI's type-erased stack. The WaddleApp NavigationStack is bound
    /// to this path, so appending/removing routes here drives all screen transitions.
    @Published var navigationPath = NavigationPath()

    // MARK: - Workout Settings (SetupView binds to these)

    @Published var settings = WorkoutSettings()

    // MARK: - Live Workout State (ActiveView reads these)

    @Published var state = WorkoutState()
    @Published var isRunning = false

    // MARK: - Services (owned by ViewModel — added in Milestone 2 & 4)
    // private let timerService = TimerService()
    // private let speechService = SpeechService()

    // MARK: - Navigation Helpers

    /// Push a new screen onto the navigation stack.
    func navigate(to route: AppRoute) {
        navigationPath.append(route)
    }

    /// Pop all screens — returns to HomeView.
    func navigateToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }

    // MARK: - Workout Actions (stubs — real logic added in Milestone 2)

    func start() {
        isRunning = true
        state.phase = .run
        state.timeRemaining = settings.runDuration
        state.currentCycle = 1
    }

    func pause() {
        state.phase = .paused
    }

    func resume() {
        state.phase = .run
    }

    func stop() {
        isRunning = false
        state.phase = .idle
    }

    // MARK: - Convenience Computed Properties

    var currentPhase: WorkoutPhase { state.phase }
    var timeRemaining: TimeInterval { state.timeRemaining }
    var currentCycle: Int { state.currentCycle }

    /// The background colour for the active screen, driven by current phase.
    var phaseColor: Color {
        switch state.phase {
        case .run:      return .runColor
        case .walk:     return .walkColor
        case .paused:   return .runColor  // keeps last colour while paused
        default:        return .runColor
        }
    }
}
