import SwiftUI

struct WeeklyDigestView: View {
    let digest: WeeklyDigest
    let strings: AppStrings
    let shareURL: URL?

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.weeklyDigestTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(strings.weeklyDigestSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer(minLength: 0)

                if let shareURL {
                    ShareLink(item: shareURL) {
                        Label(strings.weeklyDigestShareButton, systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AppTheme.cardFill)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .accessibilityLabel(strings.weeklyDigestShareButton)
                }
            }

            if digest.hasEnoughData {
                GlassCardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateRangeText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.secondaryText)

                                Text(currency(digest.totalSpend))
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }

                            Spacer(minLength: 0)

                            VStack(alignment: .trailing, spacing: 6) {
                                Text(String(format: strings.weeklyDigestExpenseCountTemplate, digest.expenseCount))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .multilineTextAlignment(.trailing)

                                if let status = digest.goalStatus {
                                    statusBadge(status)
                                }
                            }
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            metricTile(
                                label: strings.weeklyDigestTopCategoryLabel,
                                value: digest.topCategory?.displayName ?? "—",
                                tint: digest.topCategory?.accentColor ?? AppTheme.primaryText,
                                symbol: digest.topCategory?.symbolName ?? "chart.pie.fill"
                            )

                            metricTile(
                                label: strings.weeklyDigestAverageDailyLabel,
                                value: currency(digest.averageDailySpend),
                                tint: AppTheme.primaryText,
                                symbol: "calendar"
                            )

                            metricTile(
                                label: strings.weeklyDigestLargestExpenseLabel,
                                value: largestExpenseValue,
                                tint: AppTheme.primaryText,
                                symbol: "banknote.fill"
                            )

                            metricTile(
                                label: strings.weeklyDigestGoalStatusLabel,
                                value: goalStatusText,
                                tint: goalStatusColor,
                                symbol: goalStatusSymbol
                            )
                        }

                        if let comparison = digest.comparisonVsLastWeek {
                            comparisonStrip(comparison)
                        } else {
                            Text(strings.weeklyDigestNoComparisonMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        if let insight = digest.bestInsight {
                            bestInsightStrip(insight)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                EmptyStateView(
                    title: strings.weeklyDigestEmptyTitle,
                    message: strings.weeklyDigestEmptyMessage,
                    actionTitle: strings.weeklyDigestEmptyAction,
                    action: {
                        guard let url = URL(string: "pocketleak://quick-add") else { return }
                        openURL(url)
                    }
                )
            }
        }
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let start = formatter.string(from: digest.weekStart)
        let end = formatter.string(from: digest.weekEnd)
        return String(format: strings.weeklyDigestDateRangeTemplate, start, end)
    }

    private var largestExpenseValue: String {
        guard let expense = digest.largestExpense else { return "—" }
        let merchant = expense.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        if merchant.isEmpty {
            return currency(expense.amount)
        }
        return "\(currency(expense.amount)) · \(merchant)"
    }

    private var goalStatusText: String {
        guard let status = digest.goalStatus else { return strings.goalsNoGoalStatus }

        switch status {
        case .safe:
            return strings.goalForecastStatusSafe
        case .watch:
            return strings.goalForecastStatusWatch
        case .risk:
            return strings.goalForecastStatusRisk
        case .over:
            return strings.goalForecastStatusOver
        }
    }

    private var goalStatusColor: Color {
        guard let status = digest.goalStatus else {
            return AppTheme.tertiaryText
        }
        return status.tintColor
    }

    private var goalStatusSymbol: String {
        guard let status = digest.goalStatus else {
            return "circle"
        }
        return status.iconName
    }

    @ViewBuilder
    private func statusBadge(_ status: GoalForecastStatus) -> some View {
        Text(goalStatusText)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tintColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(status.tintColor.opacity(0.12))
            )
    }

    @ViewBuilder
    private func metricTile(label: String, value: String, tint: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.tertiaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    @ViewBuilder
    private func comparisonStrip(_ comparison: SpendingComparison) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings.weeklyDigestComparisonLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.tertiaryText)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: comparison.direction.iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(comparison.direction.tintColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(comparison.direction.tintColor.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(comparisonSummaryText(for: comparison))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(comparisonInterpretation(for: comparison))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.background.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.cardBorder.opacity(0.9), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(comparison.title)
        .accessibilityValue(comparisonInterpretation(for: comparison))
    }

    @ViewBuilder
    private func bestInsightStrip(_ insight: SmartInsight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings.weeklyDigestBestInsightLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.tertiaryText)

            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(insight.type.accentColor.opacity(0.14))
                    Image(systemName: insight.type.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(insight.type.accentColor)
                }
                .frame(width: 36, height: 36)

                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.background.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.cardBorder.opacity(0.9), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(insight.title)
        .accessibilityValue(insight.message)
    }

    private func comparisonSummaryText(for comparison: SpendingComparison) -> String {
        guard comparison.hasPreviousData else {
            return strings.weeklyDigestNoComparisonMessage
        }

        let directionText: String
        switch comparison.direction {
        case .up:
            directionText = String(format: strings.trendHigherMessageTemplate, currency(abs(comparison.deltaAmount)))
        case .down:
            directionText = String(format: strings.trendLowerMessageTemplate, currency(abs(comparison.deltaAmount)))
        case .flat:
            directionText = strings.trendFlatMessage
        }

        return "\(percentageLabel(for: comparison)) · \(directionText)"
    }

    private func comparisonInterpretation(for comparison: SpendingComparison) -> String {
        guard comparison.hasPreviousData else {
            return strings.weeklyDigestNoComparisonMessage
        }

        return [
            "\(strings.trendCurrentLabel): \(currency(comparison.currentAmount))",
            "\(strings.trendPreviousLabel): \(currency(comparison.previousAmount))"
        ]
        .joined(separator: " • ")
    }

    private func percentageLabel(for comparison: SpendingComparison) -> String {
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

    private func currency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}
