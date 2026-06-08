import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let subtitle: String
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    var body: some View {
        let scale = appTextSize.scale
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(AppTheme.tertiaryText)
                Text(value)
                    .font(.system(size: 24 * scale, weight: .semibold, design: .default))
                    .foregroundStyle(AppTheme.primaryText)
                Text(subtitle)
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 114 * scale, alignment: .leading)
        }
    }
}
