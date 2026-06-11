import SwiftUI

struct AppLockScreenView: View {
    let strings: AppStrings
    let biometryDescription: String
    let statusMessage: String?
    let isAuthenticating: Bool
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            GlassCardView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.cardFill)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                        .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(strings.appLockLockedTitle)
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.primaryText)
                            Text(strings.appLockLockedMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        Spacer(minLength: 0)
                    }

                    Text(strings.appLockDescription)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)

                    Text(biometryDescription)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(Color.red)
                    }

                    Button {
                        onUnlock()
                    } label: {
                        HStack(spacing: 8) {
                            if isAuthenticating {
                                ProgressView()
                                    .tint(AppTheme.background)
                            } else {
                                Image(systemName: "faceid")
                            }
                            Text(strings.appLockUnlock)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.background)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.primaryText)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isAuthenticating)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
        }
    }
}
