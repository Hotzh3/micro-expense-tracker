import SwiftUI

struct ScreenHeaderView: View {
    let title: String
    let subtitle: String
    var showsSettingsButton: Bool = false
    var settingsAction: (() -> Void)? = nil

    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.presentSettings) private var presentSettings: () -> Void

    var body: some View {
        let scale = appTextSize.scale

        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pocket Leak")
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .padding(.horizontal, 12 * scale)
                    .padding(.vertical, 5 * scale)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.chipFill)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )

                Text(title)
                    .font(.system(size: 27 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.system(size: 16 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if showsSettingsButton {
                Button {
                    (settingsAction ?? presentSettings)()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(width: 40 * scale, height: 40 * scale)
                        .background(
                            Circle()
                                .fill(AppTheme.cardFill)
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
