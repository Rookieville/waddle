// Reusable card tile for the HomeView preset grid — shows name, duration, and cycle info

import SwiftUI

// MARK: - PresetCardView

struct PresetCardView: View {

    // MARK: - Properties

    let title:       String          // Preset name or "Custom"
    let subtitle:    String          // Duration summary or "Set your own pace"
    let detail:      String?         // "Unlimited" / "8 rounds" — nil for the Custom card
    let iconName:    String?         // SF Symbol name; "plus" for Custom, nil for preset cards
    let isSelected:  Bool            // When true, draws an orange border around the card
    let isSelecting: Bool            // When true (and onDelete != nil), shows the delete button
    let onTap:       () -> Void
    let onDelete:    (() -> Void)?   // nil = card is not deletable (Custom card)

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {

            // Main tappable card
            Button(action: onTap) {
                cardContent
            }
            .buttonStyle(.plain)

            // Delete badge — visible only when parent is in select mode and card is deletable
            if isSelecting, let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red)
                        .background(Color.waddleBackground, in: Circle())
                }
                .offset(x: 6, y: -6)
            }
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.runColor)
            }

            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(.system(.caption, design: .default))
                .foregroundStyle(Color.textMuted)

            if let detail {
                Text(detail)
                    .font(.system(.caption2, design: .default))
                    .foregroundStyle(Color.textMuted)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        .padding(16)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: DesignSystem.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(isSelected ? Color.runColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        PresetCardView(
            title:       "Custom",
            subtitle:    "Set your own pace",
            detail:      nil,
            iconName:    "plus",
            isSelected:  false,
            isSelecting: false,
            onTap:       {},
            onDelete:    nil
        )
        PresetCardView(
            title:       "Beginner",
            subtitle:    "0:30 run · 2 min walk",
            detail:      "Unlimited",
            iconName:    nil,
            isSelected:  true,
            isSelecting: true,
            onTap:       {},
            onDelete:    {}
        )
    }
    .padding()
    .background(Color.waddleBackground)
}
