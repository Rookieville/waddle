// Design tokens — all colours, typography sizes, and layout constants for Waddle

import SwiftUI

// MARK: - Color Palette

extension Color {

    // MARK: Brand Colours

    /// Coral-orange — used for the RUN phase background and primary buttons.
    static let runColor = Color(hex: "FF6B35")

    /// Mint-teal — used for the WALK phase background.
    static let walkColor = Color(hex: "4ECDC4")

    /// Near-black with blue undertone — the app's primary background.
    static let waddleBackground = Color(hex: "0F0F14")

    /// Slightly lighter than background — used for cards and surface panels.
    static let surface = Color(hex: "1C1C24")

    /// Off-white — primary text colour. Easier on the eyes than pure white.
    static let textPrimary = Color(hex: "F7F7F7")

    /// Muted purple-grey — secondary labels, cycle count, inactive elements.
    static let textMuted = Color(hex: "8888A0")

    // MARK: Hex Initialiser

    /// Create a Color from a 6-digit hex string (without the leading #).
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Layout Constants

enum DesignSystem {

    // MARK: Corner Radii

    /// Standard corner radius for cards and large containers.
    static let cornerRadius: CGFloat = 20

    /// Corner radius for buttons and chips.
    static let buttonCornerRadius: CGFloat = 16

    // MARK: Spacing

    /// Standard horizontal padding for full-width content.
    static let horizontalPadding: CGFloat = 24

    /// Standard padding inside cards.
    static let cardPadding: CGFloat = 20
}
