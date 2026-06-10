import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var timeFilter: HistoryTimeFilter = .all
    @State private var selectedCategoryID: UUID? = nil
    @State private var didAnimateIn = false
    @State private var pdfExports: [ExpensePDFReportType: ExpensePDFExport] = [:]
    @State private var pdfExportErrorMessage: String?
    private let pdfExportService = ExpensePDFExportService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: strings.historyHeader,
                    subtitle: "Review saved leaks by time range and category.",
                    showsSettingsButton: true
                )

                exportCard
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)

                VStack(spacing: 12) {
                    filterCard
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)

                    if viewModel.expenses.isEmpty {
                        EmptyStateView(
                            title: strings.historyEmptyStateTitle,
                            message: strings.historyEmptyStateMessage,
                            actionTitle: strings.historyEmptyStateAction,
                            action: {
                                guard let url = URL(string: "pocketleak://quick-add") else { return }
                                openURL(url)
                            }
                        )
                    } else if filteredExpenses.isEmpty {
                        EmptyStateView(
                            title: strings.historyNoResultsTitle,
                            message: strings.historyNoResultsMessage,
                            actionTitle: strings.historyNoResultsAction,
                            action: {
                                resetFilters()
                            }
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExpenses) { expense in
                                HistoryRow(expense: expense)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            guard !didAnimateIn else { return }
            if reduceMotion {
                didAnimateIn = true
            } else {
                withAnimation(AppMotion.standard) {
                    didAnimateIn = true
                }
            }
        }
        .animation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.standard), value: didAnimateIn)
        .task(id: viewModel.pdfExportSnapshotSignature) {
            await preparePDFExports()
        }
    }

    private var filteredExpenses: [Expense] {
        let category = selectedCategoryID.flatMap { id in
            viewModel.categories.first(where: { $0.id == id })
        }
        return viewModel.expenses(matching: category, timeFilter: timeFilter)
    }

    private var selectedCategoryLabel: String {
        guard let selectedCategoryID,
              let category = viewModel.categories.first(where: { $0.id == selectedCategoryID }) else {
            return "All Categories"
        }
        return category.displayName
    }

    private var filterCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("History")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Text("Filter saved expenses by time range and category.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }

                Picker("Time range", selection: $timeFilter) {
                    ForEach(HistoryTimeFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Menu {
                    Button("All Categories") {
                        selectedCategoryID = nil
                    }

                    Divider()

                    ForEach(viewModel.categories) { category in
                        Button(category.displayName) {
                            selectedCategoryID = category.id
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Category")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                            Text(selectedCategoryLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.cardFill)
                    )
                }
                .buttonStyle(.plain)

                HStack {
                    Text("\(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Button("Reset") {
                        resetFilters()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var exportCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.exportData)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(strings.exportDescription)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                VStack(spacing: 10) {
                    ShareLink(item: viewModel.csvExport.fileURL) {
                        exportButtonLabel(title: strings.exportCSV, systemImage: "doc.text")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strings.exportCSV)
                    .accessibilityHint(strings.exportDescription)

                    ShareLink(item: viewModel.jsonExport.fileURL) {
                        exportButtonLabel(title: strings.exportJSON, systemImage: "curlybraces")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strings.exportJSON)
                    .accessibilityHint(strings.exportDescription)

                    ShareLink(item: viewModel.monthlySummaryReportText) {
                        exportButtonLabel(title: strings.exportMonthlySummary, systemImage: "text.alignleft")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strings.exportMonthlySummary)
                    .accessibilityHint(strings.exportDescription)

                    Text(strings.exportPDF)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    pdfShareLink(for: .weekly, title: strings.shareWeeklyPDFReport)
                    pdfShareLink(for: .monthly, title: strings.shareMonthlyPDFReport)
                    pdfShareLink(for: .allData, title: strings.shareAllDataPDFReport)
                }

                if let pdfExportErrorMessage {
                    Text(pdfExportErrorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }
            }
        }
    }

    private func exportButtonLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AppTheme.background)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.primaryText)
        )
    }

    private func resetFilters() {
        timeFilter = .all
        selectedCategoryID = nil
    }

    @ViewBuilder
    private func pdfShareLink(for type: ExpensePDFReportType, title: String) -> some View {
        if let export = pdfExports[type] {
            ShareLink(item: export.fileURL) {
                exportButtonLabel(title: title, systemImage: "doc.richtext")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityHint(strings.exportDescription)
        } else {
            Button {
                // Intentionally left empty. The PDF is prepared in the background.
            } label: {
                exportButtonLabel(title: title, systemImage: "doc.richtext")
            }
            .buttonStyle(.plain)
            .disabled(true)
            .accessibilityLabel(title)
            .accessibilityHint(strings.exportDescription)
        }
    }

    @MainActor
    private func preparePDFExports() async {
        let monthlyReport = viewModel.pdfReportData(for: .monthly)
        let weeklyReport = viewModel.pdfReportData(for: .weekly)
        let allDataReport = viewModel.pdfReportData(for: .allData)

        let monthlyExport = pdfExportService.export(report: monthlyReport)
        let weeklyExport = pdfExportService.export(report: weeklyReport)
        let allDataExport = pdfExportService.export(report: allDataReport)

        var exports: [ExpensePDFReportType: ExpensePDFExport] = [:]
        if let weeklyExport { exports[.weekly] = weeklyExport }
        if let monthlyExport { exports[.monthly] = monthlyExport }
        if let allDataExport { exports[.allData] = allDataExport }
        pdfExports = exports

        if monthlyExport == nil || weeklyExport == nil || allDataExport == nil {
            pdfExportErrorMessage = strings.pdfExportFailed
        } else {
            pdfExportErrorMessage = nil
        }
    }
}

private struct HistoryRow: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    let expense: Expense

    var body: some View {
        GlassCardView {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formattedAmount(expense.amount))
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Text(expense.category.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AppTheme.chipFill)
                            )
                    }

                    if !expense.merchant.isEmpty {
                        Text(expense.merchant)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !expense.note.isEmpty {
                        Text(expense.note)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                }

                Spacer()

                Button {
                    viewModel.deleteExpense(id: expense.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 44, height: 44)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(AppTheme.cardFill)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.current().deleteExpenseAccessibilityLabel)
                .accessibilityHint(AppStrings.current().deleteExpenseHint)
            }
        }
    }

    private func formattedAmount(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}
