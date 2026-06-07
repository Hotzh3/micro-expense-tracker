import SwiftUI

struct ScreenHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pocket Leak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppTheme.chipFill)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                        )
                )

            Text(title)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
