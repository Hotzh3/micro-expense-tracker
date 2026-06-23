import SwiftUI

struct CalendarReviewView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    @State private var selectedDate = Date.now

    private var scale: CGFloat {
        appTextSize.scale
    }

    private var monthReview: ExpenseViewModel.CalendarMonthReview {
        viewModel.calendarMonthReview
    }

    private var selectedDayReview: ExpenseViewModel.CalendarDayReview {
        viewModel.calendarDayReview(for: selectedDate)
    }

    var body: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Calendar Review")
                        .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("Monthly view with day-level expense details.")
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                monthSummary

                monthGrid

                selectedDayDetail
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            if !monthReview.days.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                selectedDate = monthReview.highestDay?.date ?? monthReview.days.first?.date ?? .now
            }
        }
    }

    private var monthSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(monthTitle)
                        .font(.system(size: 16 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("\(monthReview.daysWithExpenses) days with expenses")
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.displayCurrency(monthReview.totalSpend))
                        .font(.system(size: 16 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Monthly total")
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            if let highestDay = monthReview.highestDay {
                Text("Highest day: \(highestDay.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
    }

    private var monthGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        let leadingCount = max(leadingDayCount(for: monthReview.monthStart), 0)

        return VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Calendar.current.shortStandaloneWeekdaySymbols.indices, id: \.self) { index in
                    Text(Calendar.current.shortStandaloneWeekdaySymbols[index])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<leadingCount, id: \.self) { _ in
                    Color.clear.frame(height: 44)
                }

                ForEach(monthReview.days) { day in
                    dayCell(for: day)
                }
            }
        }
    }

    private func dayCell(for day: ExpenseViewModel.CalendarDayReview) -> some View {
        let isSelected = Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
        let hasExpenses = day.total > 0
        let fillOpacity = hasExpenses ? min(max(day.total / max(monthReview.averageDailySpend, 1), 0.18), 0.95) : 0.06

        return Button {
            selectedDate = day.date
        } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.system(size: 14 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(day.isCurrentMonth ? AppTheme.primaryText : AppTheme.tertiaryText)

                if hasExpenses {
                    Circle()
                        .fill(AppTheme.primaryText)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(day.isCurrentMonth ? AppTheme.cardFill.opacity(fillOpacity) : AppTheme.cardFill.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? AppTheme.primaryText : AppTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.date.formatted(date: .complete, time: .omitted))
        .accessibilityValue(hasExpenses ? viewModel.displayCurrency(day.total) : "No expenses")
    }

    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDayReview.date.formatted(date: .complete, time: .omitted))
                        .font(.system(size: 16 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(selectedDayReview.averageComparisonText)
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Text(viewModel.displayCurrency(selectedDayReview.total))
                    .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Text(selectedDayReview.insightText)
                .font(.system(size: 13 * scale))
                .foregroundStyle(AppTheme.secondaryText)

            if let topMerchant = selectedDayReview.topMerchant {
                detailRow(label: "Top merchant", value: topMerchant)
            }

            if let highestExpense = selectedDayReview.highestExpense {
                let merchant = highestExpense.merchant.isEmpty ? highestExpense.category.displayName : highestExpense.merchant
                detailRow(label: "Highest expense", value: "\(viewModel.displayCurrency(highestExpense.amount)) · \(merchant)")
            }

            if !selectedDayReview.categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category breakdown")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                    ForEach(selectedDayReview.categoryBreakdown) { item in
                        HStack {
                            Text(item.category.displayName)
                                .font(.system(size: 13 * scale))
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(viewModel.displayCurrency(item.total))
                                .font(.system(size: 13 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                }
            }

            if !selectedDayReview.expenses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expenses")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                    ForEach(selectedDayReview.expenses) { expense in
                        expenseRow(expense)
                    }
                }
            } else {
                Text("No expenses recorded on this day.")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.top, 4)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.tertiaryText)
            Spacer()
            Text(value)
                .font(.system(size: 13 * scale))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant.isEmpty ? expense.category.displayName : expense.merchant)
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(expense.category.displayName)
                    .font(.system(size: 12 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Text(viewModel.displayCurrency(expense.amount))
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(.vertical, 6)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: monthReview.monthStart)
    }

    private func leadingDayCount(for monthStart: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: monthStart)
        let firstWeekday = Calendar.current.firstWeekday
        let offset = (weekday - firstWeekday + 7) % 7
        return offset
    }
}
