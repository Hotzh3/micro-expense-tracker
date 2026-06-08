import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    var body: some View {
        let scale = appTextSize.scale
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 28 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Text(title)
                .font(.system(size: 20 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
            Text(message)
                .font(.system(size: 15 * scale))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30 * scale)
        .padding(.horizontal, 22 * scale)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}
