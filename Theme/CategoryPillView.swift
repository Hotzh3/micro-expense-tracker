import SwiftUI

struct CategoryPillView: View {
    let category: ExpenseCategory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.symbolName)
                .font(.caption2.weight(.semibold))
            Text(category.displayName)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(AppTheme.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
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
