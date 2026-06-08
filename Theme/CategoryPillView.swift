import SwiftUI

struct CategoryPillView: View {
    let category: ExpenseCategory
    let isSelected: Bool
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    var body: some View {
        let scale = appTextSize.scale
        HStack(spacing: 6) {
            Image(systemName: category.symbolName)
                .font(.system(size: 12 * scale, weight: .semibold))
            Text(category.displayName)
                .font(.system(size: 13 * scale, weight: .medium))
        }
        .foregroundStyle(AppTheme.primaryText)
        .padding(.horizontal, 14 * scale)
        .padding(.vertical, 10 * scale)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? AppTheme.chipSelectedFill : AppTheme.chipFill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}
