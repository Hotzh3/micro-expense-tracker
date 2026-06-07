import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
                Text(value)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 102, alignment: .leading)
        }
    }
}
