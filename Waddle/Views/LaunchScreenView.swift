// Launch screen — coral-orange splash shown only on cold launch

import SwiftUI

// MARK: - LaunchScreenView

struct LaunchScreenView: View {

    // MARK: - State

    @State private var opacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full-bleed coral background — matches the app icon background
            Color.runColor
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // App icon — loaded via UIKit bridge (no .imageset exists for AppIcon)
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                    .resizable()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)

                Spacer().frame(height: 8)

                // App name
                Text("Waddle")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                // Tagline
                Text("No shame in the waddle.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .opacity(opacity)
        .onAppear {
            // Fade in over 0.5 s on first render
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchScreenView()
}
