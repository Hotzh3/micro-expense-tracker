import SwiftUI

struct SpendingComparisonCardView: View {
    let comparison: SpendingComparison
    let strings: AppStrings
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
                            .fill(comparison.direction.tintColor.opacity(0.14))
                        Image(systemName: comparison.direction.iconName)
                            .font(.system(size: 16 * scale, weight: .semibold))
                            .foregroundStyle(comparison.direction.tintColor)
                    }
                    .frame(width: 40 * scale, height: 40 * scale)

                    VStack(alignment: .leading, spacing: 4 * scale) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(comparison.title)
                                .font(.system(size: 17 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)

                            Spacer(minLength: 0)

                            Text(changeLabel)
                                .font(.system(size: 12 * scale, weight: .semibold))
                                .foregroundStyle(comparison.direction.tintColor)
                                .padding(.horizontal, 8 * scale)
                                .padding(.vertical, 5 * scale)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(comparison.direction.tintColor.opacity(0.12))
                                )
                        }

                        Text(viewModel.privacyAwareText(interpretation))
                            .font(.system(size: compact ? 13 * scale : 14 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(compact ? 3 : 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                comparisonRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(comparison.title)
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private var comparisonRow: some View {
        HStack(spacing: 10 * appTextSize.scale) {
            amountBlock(
                title: strings.trendCurrentLabel,
                amount: comparison.currentAmount,
                tint: AppTheme.primaryText
            )

            Divider()
                .frame(height: 28 * appTextSize.scale)

            amountBlock(
                title: strings.trendPreviousLabel,
                amount: comparison.previousAmount,
                tint: AppTheme.secondaryText
            )
        }
    }

    private func amountBlock(title: String, amount: Double, tint: Color) -> some View {
            VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
            Text(viewModel.displayCurrency(amount))
                .font(.system(size: 16 * appTextSize.scale, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var interpretation: String {
        guard comparison.hasPreviousData else {
            return strings.trendNoPreviousDataMessage
        }

        switch comparison.direction {
        case .up:
            return String(format: strings.trendHigherMessageTemplate, viewModel.displayCurrency(abs(comparison.deltaAmount)))
        case .down:
            return String(format: strings.trendLowerMessageTemplate, viewModel.displayCurrency(abs(comparison.deltaAmount)))
        case .flat:
            return strings.trendFlatMessage
        }
    }

    private var changeLabel: String {
        guard comparison.hasPreviousData else { return "—" }

        switch comparison.direction {
        case .up:
            return String(format: "+%.0f%%", comparison.percentChange)
        case .down:
            return String(format: "−%.0f%%", comparison.percentChange)
        case .flat:
            return "0%"
        }
    }

    private var accessibilityValue: String {
        if comparison.hasPreviousData {
            return [
                strings.trendCurrentLabel + ": " + viewModel.displayCurrency(comparison.currentAmount),
                strings.trendPreviousLabel + ": " + viewModel.displayCurrency(comparison.previousAmount),
                String(format: "%.0f%%", comparison.percentChange),
                viewModel.privacyAwareText(interpretation)
            ]
            .joined(separator: ". ")
        }

        return [
            strings.trendCurrentLabel + ": " + viewModel.displayCurrency(comparison.currentAmount),
            strings.trendPreviousLabel + ": " + viewModel.displayCurrency(comparison.previousAmount),
            viewModel.privacyAwareText(interpretation)
        ]
        .joined(separator: ". ")
    }
}
