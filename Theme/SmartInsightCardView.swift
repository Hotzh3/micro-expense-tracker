import SwiftUI

struct SmartInsightCardView: View {
    let insight: SmartInsight
    var compact: Bool = false

    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    var body: some View {
        let scale = appTextSize.scale
        GlassCardView {
            VStack(alignment: .leading, spacing: 12 * scale) {
                HStack(alignment: .top, spacing: 12 * scale) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                            .fill(insight.type.accentColor.opacity(0.14))
                        Image(systemName: insight.type.iconName)
                            .font(.system(size: 16 * scale, weight: .semibold))
                            .foregroundStyle(insight.type.accentColor)
                    }
                    .frame(width: 40 * scale, height: 40 * scale)

                    VStack(alignment: .leading, spacing: 4 * scale) {
                        Text(insight.title)
                            .font(.system(size: 17 * scale, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(viewModel.privacyAwareText(insight.message))
                            .font(.system(size: compact ? 13 * scale : 14 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(compact ? 3 : 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !compact {
                    insightMetadataRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(insight.title)
        .accessibilityValue(viewModel.privacyAwareText(insight.message))
    }

    @ViewBuilder
    private var insightMetadataRow: some View {
        let items = metadataItems
        if !items.isEmpty {
            HStack(alignment: .center, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Label {
                        Text(item.label)
                    } icon: {
                        Image(systemName: item.symbolName)
                    }
                    .font(.system(size: 12 * appTextSize.scale, weight: .semibold))
                    .foregroundStyle(item.tint)
                    .padding(.horizontal, 10 * appTextSize.scale)
                    .padding(.vertical, 7 * appTextSize.scale)
                    .background(
                        Capsule(style: .continuous)
                            .fill(item.tint.opacity(0.12))
                    )
                    .accessibilityLabel(item.label)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var metadataItems: [MetadataItem] {
        var items: [MetadataItem] = []

        if let category = insight.category {
            items.append(
                MetadataItem(
                    label: category.displayName,
                    symbolName: category.symbolName,
                    tint: category.accentColor
                )
            )
        }

        if let amount = insight.amount {
            items.append(
                MetadataItem(
                    label: viewModel.displayCurrency(amount),
                    symbolName: "banknote.fill",
                    tint: insight.type.accentColor
                )
            )
        }

        if let percentChange = insight.percentChange {
            items.append(
                MetadataItem(
                    label: String(format: "%+.0f%%", percentChange),
                    symbolName: insight.type.iconName,
                    tint: insight.type.accentColor
                )
            )
        }

        return items
    }

    private struct MetadataItem {
        let label: String
        let symbolName: String
        let tint: Color
    }
}
