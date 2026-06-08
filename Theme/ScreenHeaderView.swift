import SwiftUI

struct ScreenHeaderView: View {
    let title: String
    let subtitle: String
    var showsSettingsButton: Bool = false
    var settingsAction: (() -> Void)? = nil

    @Environment(\.presentSettings) private var presentSettings

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pocket Leak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.chipFill)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )

                Text(title)
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if showsSettingsButton {
                Button {
                    (settingsAction ?? presentSettings)()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(width: 36, height: 36)
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
