import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var historyFilter = ExpenseFilter()
    @State private var draftFilter = ExpenseFilter()
    @State private var showFilterSheet = false
    @State private var didAnimateIn = false
    @State private var csvExport: ExpenseCSVExport?
    @State private var jsonExport: ExpenseJSONExport?
    @State private var pdfExports: [ExpensePDFReportType: ExpensePDFExport] = [:]
    @State private var pdfExportErrorMessage: String?
    private let pdfExportService = ExpensePDFExportService()

    var body: some View {
        let summary = viewModel.historySummary(using: historyFilter)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenHeaderView(
                    title: strings.historyHeader,
                    subtitle: strings.historyHeaderSubtitle,
                    showsSettingsButton: true
                )

                searchAndFilterCard
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)

                filteredSummaryCard(summary: summary)
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)

                exportCard
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
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)
                } else if summary.filteredExpenses.isEmpty {
                    EmptyStateView(
                        title: strings.historyNoResultsTitle,
                        message: strings.historyNoResultsMessage,
                        actionTitle: strings.historyNoResultsAction,
                        action: {
                            resetFilters()
                        }
                    )
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(summary.filteredExpenses) { expense in
                            HistoryRow(expense: expense)
                        }
                    }
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $showFilterSheet) {
            HistoryFilterSheetView(
                filter: $draftFilter,
                availableMerchants: viewModel.availableMerchants,
                categories: viewModel.categories,
                onApply: {
                    historyFilter = draftFilter
                    showFilterSheet = false
                },
                onReset: {
                    draftFilter = ExpenseFilter()
                    historyFilter = draftFilter
                    showFilterSheet = false
                },
                onCancel: {
                    showFilterSheet = false
                }
            )
            .presentationDetents([.medium, .large])
        }
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
        .task(id: exportSignature) {
            await prepareExports()
        }
    }

    private var filteredExpenses: [Expense] {
        viewModel.historySummary(using: historyFilter).filteredExpenses
    }

    private var filteredTotal: Double {
        viewModel.historySummary(using: historyFilter).filteredTotal
    }

    private var filteredCount: Int {
        viewModel.historySummary(using: historyFilter).filteredCount
    }

    private var exportExpenses: [Expense] {
        historyFilter.isActive ? filteredExpenses : viewModel.expenses
    }

    private var exportSignature: String {
        let expenseSignature = exportExpenses
            .map { "\($0.id.uuidString):\($0.amount):\($0.date.timeIntervalSince1970):\($0.category.id.uuidString):\($0.merchant):\($0.note):\($0.source.rawValue)" }
            .joined(separator: ",")

        return [historyFilter.signature, String(exportExpenses.count), expenseSignature].joined(separator: "|")
    }

    private var searchAndFilterCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.secondaryText)

                    TextField(
                        strings.historySearchPlaceholder,
                        text: $historyFilter.searchText
                    )
                    .textFieldStyle(.plain)
                    .foregroundColor(AppTheme.primaryText)
                    .tint(AppTheme.primaryText)
                    .accentColor(AppTheme.primaryText)

                    if !historyFilter.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            historyFilter.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(strings.historyClearFilters)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.inputFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.inputBorder, lineWidth: 1)
                        )
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: dateRangeLabel(for: historyFilter.dateRange), systemImage: "calendar")

                        if !historyFilter.categories.isEmpty {
                            filterChip(title: "\(historyFilter.categories.count) \(strings.historyFilterCategoriesTitle)", systemImage: "tag")
                        }

                        if !historyFilter.merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            filterChip(title: historyFilter.merchant, systemImage: "building.2")
                        }

                        if let source = historyFilter.source {
                            filterChip(title: source.displayName, systemImage: "line.3.horizontal.decrease.circle")
                        }

                        if let minAmount = historyFilter.minAmount {
                            filterChip(title: "Min \(viewModel.displayCurrency(minAmount))", systemImage: "arrow.up.right")
                        }

                        if let maxAmount = historyFilter.maxAmount {
                            filterChip(title: "Max \(viewModel.displayCurrency(maxAmount))", systemImage: "arrow.down.left")
                        }

                        if historyFilter.sortOrder != .newest {
                            filterChip(title: historyFilter.sortOrder.title, systemImage: "arrow.up.arrow.down")
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        draftFilter = historyFilter
                        showFilterSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                            Text(strings.historyFiltersButton)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.background)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.primaryText)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        resetFilters()
                    } label: {
                        Text(strings.historyClearFilters)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.cardFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!historyFilter.isActive)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func filteredSummaryCard(summary: ExpenseViewModel.HistorySummary) -> some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.historyFilteredTotalTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MetricCardView(
                        title: strings.historyFilteredCountTitle,
                        value: "\(summary.filteredCount)",
                        subtitle: historyFilter.isActive ? strings.historyFilteredResultsSubtitle : strings.historyAllExpensesSubtitle
                    )
                    MetricCardView(
                        title: strings.pdfTotalSpent,
                        value: viewModel.displayCurrency(summary.filteredTotal),
                        subtitle: historyFilter.isActive ? strings.historyFilteredResultsSubtitle : strings.historyAllExpensesSubtitle
                    )
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
                    if let csvExport {
                        ShareLink(item: csvExport.fileURL) {
                            exportButtonLabel(title: strings.exportCSV, systemImage: "doc.text")
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            // Intentionally left empty. The CSV is prepared in the background.
                        } label: {
                            exportButtonLabel(title: strings.exportCSV, systemImage: "doc.text")
                        }
                        .buttonStyle(.plain)
                        .disabled(true)
                    }

                    if let jsonExport {
                        ShareLink(item: jsonExport.fileURL) {
                            exportButtonLabel(title: strings.exportJSON, systemImage: "curlybraces")
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            // Intentionally left empty. The JSON is prepared in the background.
                        } label: {
                            exportButtonLabel(title: strings.exportJSON, systemImage: "curlybraces")
                        }
                        .buttonStyle(.plain)
                        .disabled(true)
                    }

                    ShareLink(item: viewModel.monthlySummaryReportText) {
                        exportButtonLabel(title: strings.exportMonthlySummary, systemImage: "text.alignleft")
                    }
                    .buttonStyle(.plain)

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
        historyFilter = ExpenseFilter()
        draftFilter = ExpenseFilter()
    }

    private func filterChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.chipFill)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
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
    private func prepareExports() async {
        let exportExpenses = exportExpenses
        let csv = viewModel.csvExport(for: exportExpenses)
        let json = viewModel.jsonExport(for: exportExpenses)
        let weeklyReport = viewModel.pdfReportData(for: .weekly, expenses: exportExpenses)
        let monthlyReport = viewModel.pdfReportData(for: .monthly, expenses: exportExpenses)
        let allDataReport = viewModel.pdfReportData(for: .allData, expenses: exportExpenses)

        let weeklyExport = pdfExportService.export(report: weeklyReport)
        let monthlyExport = pdfExportService.export(report: monthlyReport)
        let allDataExport = pdfExportService.export(report: allDataReport)

        var exports: [ExpensePDFReportType: ExpensePDFExport] = [:]
        if let weeklyExport { exports[.weekly] = weeklyExport }
        if let monthlyExport { exports[.monthly] = monthlyExport }
        if let allDataExport { exports[.allData] = allDataExport }

        self.csvExport = csv
        self.jsonExport = json
        pdfExports = exports

        if monthlyExport == nil || weeklyExport == nil || allDataExport == nil {
            pdfExportErrorMessage = strings.pdfExportFailed
        } else {
            pdfExportErrorMessage = nil
        }
    }

    private func dateRangeLabel(for range: ExpenseDateRange) -> String {
        if range.isAll {
            return strings.historyFilterAllDates
        }

        if let startDate = range.startDate, let endDate = range.endDate {
            let formatter = PocketLeakFormatters.shortDateRangeFormatter
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }

        return strings.historyFilterAllDates
    }
}

private struct HistoryFilterSheetView: View {
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    @Binding var filter: ExpenseFilter
    let availableMerchants: [String]
    let categories: [ExpenseCategory]
    let onApply: () -> Void
    let onReset: () -> Void
    let onCancel: () -> Void

    @State private var merchantSearchText: String = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case merchant
        case minAmount
        case maxAmount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    headerCard
                    dateRangeCard
                    categoryCard
                    merchantCard
                    sourceCard
                    amountCard
                    sortCard
                }
                .padding(16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(strings.historyFilterSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(strings.cancel) {
                        onCancel()
                    }
                    .foregroundStyle(AppTheme.primaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.historyFilterResetButton) {
                        onReset()
                    }
                    .foregroundStyle(AppTheme.primaryText)
                }
            }
            .onAppear {
                merchantSearchText = filter.merchant
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(strings.done) {
                        focusedField = nil
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 6) {
                Text(strings.historyFilterSheetTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.historyFilterSheetSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                HStack {
                    Button(strings.historyFilterApplyButton) {
                        filter.merchant = merchantSearchText
                        onApply()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primaryText)
                    )
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dateRangeCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.historyFilterDateTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                HStack(spacing: 8) {
                    filterToggle(strings.historyFilterAllDates, isSelected: filter.dateRange.isAll) {
                        filter.dateRange = .all
                    }
                    filterToggle(strings.historyFilterToday, isSelected: !filter.dateRange.isAll && filter.dateRange.signature == ExpenseDateRange.today().signature) {
                        filter.dateRange = .today()
                    }
                    filterToggle(strings.historyFilterWeek, isSelected: !filter.dateRange.isAll && filter.dateRange.signature == ExpenseDateRange.week().signature) {
                        filter.dateRange = .week()
                    }
                    filterToggle(strings.historyFilterMonth, isSelected: !filter.dateRange.isAll && filter.dateRange.signature == ExpenseDateRange.month().signature) {
                        filter.dateRange = .month()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var categoryCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(strings.historyFilterCategoriesTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Button(strings.historyFilterAllCategories) {
                        filter.categories.removeAll()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 10)], spacing: 8) {
                    ForEach(categories) { category in
                        CategoryPillView(category: category, isSelected: filter.categories.contains(category))
                            .onTapGesture {
                                if filter.categories.contains(category) {
                                    filter.categories.remove(category)
                                } else {
                                    filter.categories.insert(category)
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var merchantCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.historyFilterMerchantTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                TextField(
                    strings.historyFilterMerchantTitle,
                    text: $merchantSearchText
                )
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .merchant)
                .foregroundColor(AppTheme.primaryText)
                .tint(AppTheme.primaryText)
                .accentColor(AppTheme.primaryText)
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.inputFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.inputBorder, lineWidth: 1)
                        )
                )

                if !availableMerchants.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableMerchants.prefix(6), id: \.self) { merchant in
                                Button {
                                    merchantSearchText = merchant
                                } label: {
                                    Text(merchant)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(AppTheme.chipFill)
                                                .overlay(
                                                    Capsule(style: .continuous)
                                                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sourceCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.historyFilterSourceTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                Menu {
                    Button(strings.historyFilterAllSources) {
                        filter.source = nil
                    }

                    Divider()

                    ForEach(ExpenseSource.allCases) { source in
                        Button(source.displayName) {
                            filter.source = source
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strings.historyFilterSourceTitle)
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                            Text(filter.source?.displayName ?? strings.historyFilterAllSources)
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var amountCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.historyFilterAmountRangeTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                HStack(spacing: 10) {
                    amountTextField(
                        placeholder: strings.historyFilterMinAmountPlaceholder,
                        text: Binding(
                            get: { stringAmount(filter.minAmount) },
                            set: { filter.minAmount = doubleValue($0) }
                        ),
                        field: .minAmount
                    )

                    amountTextField(
                        placeholder: strings.historyFilterMaxAmountPlaceholder,
                        text: Binding(
                            get: { stringAmount(filter.maxAmount) },
                            set: { filter.maxAmount = doubleValue($0) }
                        ),
                        field: .maxAmount
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sortCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.historySortTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                Picker(strings.historySortTitle, selection: $filter.sortOrder) {
                    ForEach(ExpenseFilterSortOrder.allCases) { sortOrder in
                        Text(sortOrder.title).tag(sortOrder)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func amountTextField(placeholder: String, text: Binding<String>, field: Field) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .textFieldStyle(.plain)
            .focused($focusedField, equals: field)
            .foregroundColor(AppTheme.primaryText)
            .tint(AppTheme.primaryText)
            .accentColor(AppTheme.primaryText)
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.inputFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.inputBorder, lineWidth: 1)
                    )
            )
    }

    private func filterToggle(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? AppTheme.chipSelectedFill : AppTheme.chipFill)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func stringAmount(_ value: Double?) -> String {
        guard let value else { return "" }
        return String(format: "%.2f", value)
    }

    private func doubleValue(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value.isFinite else { return nil }
        return value
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

                    Text(PocketLeakFormatters.historyRowDateFormatter.string(from: expense.date))
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
        viewModel.displayCurrency(amount)
    }
}
