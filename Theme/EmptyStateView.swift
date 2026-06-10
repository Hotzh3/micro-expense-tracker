import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    init(title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

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

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12 * scale)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.primaryText)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
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
