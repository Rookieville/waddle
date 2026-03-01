// Root entry point — creates the IntervalViewModel and wires up the NavigationStack for the whole app

import SwiftUI

@main
struct WaddleApp: App {

    // MARK: - State

    /// @StateObject means SwiftUI creates this once and owns its lifetime.
    /// Child views receive it via .environmentObject and use @EnvironmentObject — they observe but don't own.
    @StateObject private var viewModel    = IntervalViewModel()
    @StateObject private var presetStore  = PresetStore()

    /// true on every cold launch (process start resets @State); background resumes never retrigger the splash.
    @State private var showLaunch = true

    // MARK: - Init

    init() {
        // Register default values so UserDefaults.bool(forKey:) returns the right
        // value before the user has ever opened SettingsView.
        UserDefaults.standard.register(defaults: [
            UserSettingsKey.voiceEnabled:     true,
            UserSettingsKey.hapticsEnabled:   true,
            UserSettingsKey.countdownEnabled: false,
        ])
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app — always present underneath the splash so the NavigationStack
                // is never torn down or recreated mid-transition.
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
                .environmentObject(presetStore)
                .preferredColorScheme(.dark)

                // Launch screen — sits on top and fades out after 1.8 s.
                // Timing: fade-in 0–0.5 s → visible 0.5–1.8 s → fade-out 1.8–2.2 s.
                if showLaunch {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.4), value: showLaunch)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    showLaunch = false
                }
            }
        }
    }
}
