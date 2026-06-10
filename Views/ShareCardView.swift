import SwiftUI

enum ShareCardVariant: String, CaseIterable, Identifiable {
    case weeklySummary
    case monthlySummary
    case goalProgress
    case topCategory

    var id: String { rawValue }
}

struct ShareCardChip: Identifiable {
    let id = UUID()
    let title: String
    let tint: Color
}

struct ShareCardModel {
    let variant: ShareCardVariant
    let badgeLabel: String
    let title: String
    let periodLabel: String
    let bigValueLabel: String
    let accentColor: Color
    let symbolName: String
    let chips: [ShareCardChip]
    let message: String
}

struct ShareCardView: View {
    let model: ShareCardModel
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    var body: some View {
        let scale = appTextSize.scale

        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.background,
                    model.accentColor.opacity(0.16),
                    AppTheme.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 48 * scale, style: .continuous)
                .fill(AppTheme.background.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 48 * scale, style: .continuous)
                        .stroke(AppTheme.cardBorder.opacity(0.9), lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 28 * scale) {
                header(scale: scale)

                VStack(alignment: .leading, spacing: 10 * scale) {
                    Text(model.title)
                        .font(.system(size: 52 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    Text(model.periodLabel)
                        .font(.system(size: 26 * scale, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 18 * scale) {
                    Text(model.bigValueLabel)
                        .font(.system(size: 88 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if !model.chips.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12 * scale) {
                            ForEach(model.chips) { chip in
                                shareChip(chip, scale: scale)
                            }
                        }
                    }

                    Text(model.message)
                        .font(.system(size: 24 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }

                HStack {
                    Text("Pocket Leak")
                        .font(.system(size: 20 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.tertiaryText)
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 18 * scale, weight: .semibold))
                        .foregroundStyle(model.accentColor)
                }
            }
            .padding(48 * scale)
        }
        .frame(width: 1080, height: 1350)
        .clipped()
    }

    @ViewBuilder
    private func header(scale: CGFloat) -> some View {
        HStack(spacing: 12 * scale) {
            ZStack {
                RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                    .fill(model.accentColor.opacity(0.14))
                Image(systemName: model.symbolName)
                    .font(.system(size: 20 * scale, weight: .semibold))
                    .foregroundStyle(model.accentColor)
            }
            .frame(width: 52 * scale, height: 52 * scale)

            VStack(alignment: .leading, spacing: 2 * scale) {
                Text("Pocket Leak")
                    .font(.system(size: 24 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(model.periodLabel)
                    .font(.system(size: 18 * scale, weight: .medium))
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            Spacer()

            Text(model.badgeLabel)
                .font(.system(size: 16 * scale, weight: .semibold))
                .foregroundStyle(model.accentColor)
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 8 * scale)
                .background(
                    Capsule(style: .continuous)
                        .fill(model.accentColor.opacity(0.12))
                )
        }
    }

    @ViewBuilder
    private func shareChip(_ chip: ShareCardChip, scale: CGFloat) -> some View {
        HStack(spacing: 8 * scale) {
            Circle()
                .fill(chip.tint)
                .frame(width: 9 * scale, height: 9 * scale)
            Text(chip.title)
                .font(.system(size: 18 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14 * scale)
        .padding(.vertical, 12 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}
