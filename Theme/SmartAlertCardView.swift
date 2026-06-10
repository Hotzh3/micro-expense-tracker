import SwiftUI

struct SmartAlertCardView: View {
    let alert: SmartAlert
    let strings: AppStrings
    var dismissAction: (() -> Void)? = nil

    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    var body: some View {
        let scale = appTextSize.scale

        GlassCardView {
            VStack(alignment: .leading, spacing: 12 * scale) {
                HStack(alignment: .top, spacing: 12 * scale) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                            .fill(alert.severity.tintColor.opacity(0.14))
                        Image(systemName: alert.type.iconName)
                            .font(.system(size: 16 * scale, weight: .semibold))
                            .foregroundStyle(alert.severity.tintColor)
                    }
                    .frame(width: 40 * scale, height: 40 * scale)

                    VStack(alignment: .leading, spacing: 4 * scale) {
                        Text(alert.title)
                            .font(.system(size: 17 * scale, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Text(alert.message)
                            .font(.system(size: 14 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let dismissAction {
                        Button(action: dismissAction) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.tertiaryText)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(strings.smartAlertsDismiss)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(alert.title)
        .accessibilityValue(alert.message)
    }
}
