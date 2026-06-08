import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    var body: some View {
        let scale = appTextSize.scale
        Button(action: action) {
            Text(title)
                .font(.system(size: 17 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15 * scale)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.primaryText)
                )
        }
        .buttonStyle(.plain)
    }
}
