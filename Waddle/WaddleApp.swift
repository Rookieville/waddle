// Root entry point — creates the IntervalViewModel and wires up the NavigationStack for the whole app

import SwiftUI

@main
struct WaddleApp: App {

    // MARK: - State

    /// @StateObject means SwiftUI creates this once and owns its lifetime.
    /// Child views receive it via .environmentObject and use @EnvironmentObject — they observe but don't own.
    @StateObject private var viewModel = IntervalViewModel()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $viewModel.navigationPath) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .setup:
                            SetupView()
                        case .active:
                            ActiveView()
                        case .done:
                            DoneView()
                        }
                    }
            }
            .environmentObject(viewModel)
            .preferredColorScheme(.dark)
        }
    }
}
