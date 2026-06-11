import SwiftUI

struct RecurringExpensesView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var editorContext: RecurringEditorContext?
    @State private var pendingRemovalRecurring: RecurringExpense?
    @State private var didAnimateIn = false

    private var scale: CGFloat {
        appTextSize.scale
    }

    private struct RecurringEditorContext: Identifiable {
        let id = UUID()
        let recurringID: UUID?
        let merchant: String
        let amountText: String
        let category: ExpenseCategory
        let cadence: RecurringExpenseCadence
        let nextDueDate: Date
        let isActive: Bool
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    headerCard
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)

                    upcomingSummaryCard
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)

                    if viewModel.activeRecurringExpenses.isEmpty {
                        EmptyStateView(
                            title: strings.recurringExpensesEmptyTitle,
                            message: strings.recurringExpensesEmptyMessage,
                            actionTitle: strings.recurringExpensesCreateButton,
                            action: {
                                editorContext = RecurringEditorContext(
                                    recurringID: nil,
                                    merchant: "",
                                    amountText: "",
                                    category: viewModel.categories.first ?? .other,
                                    cadence: .monthly,
                                    nextDueDate: .now,
                                    isActive: true
                                )
                            }
                        )
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(strings.recurringExpensesTitle)
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)

                            VStack(spacing: 12) {
                                ForEach(viewModel.upcomingRecurringExpenses) { recurring in
                                    recurringExpenseCard(for: recurring)
                                }
                            }
                        }
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(strings.recurringExpensesTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.done) {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.primaryText)
                }
            }
            .confirmationDialog(
                strings.recurringExpensesRemoveConfirmationTitle,
                isPresented: Binding(
                    get: { pendingRemovalRecurring != nil },
                    set: { if !$0 { pendingRemovalRecurring = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(strings.recurringExpensesDeleteButton, role: .destructive) {
                    if let recurring = pendingRemovalRecurring {
                        viewModel.removeRecurringExpense(id: recurring.id)
                    }
                    pendingRemovalRecurring = nil
                }
                Button(strings.cancel, role: .cancel) {}
            } message: {
                Text(strings.recurringExpensesRemoveConfirmationMessage)
            }
            .sheet(item: $editorContext) { context in
                RecurringExpenseEditorView(
                    recurringID: context.recurringID,
                    initialMerchant: context.merchant,
                    initialAmountText: context.amountText,
                    initialCategory: context.category,
                    initialCadence: context.cadence,
                    initialNextDueDate: context.nextDueDate,
                    initialIsActive: context.isActive,
                    categories: viewModel.categories,
                    onSave: { recurringID, merchant, amount, category, cadence, nextDueDate, isActive in
                        viewModel.saveRecurringExpense(
                            recurringID: recurringID,
                            merchant: merchant,
                            amount: amount,
                            category: category,
                            cadence: cadence,
                            nextDueDate: nextDueDate,
                            isActive: isActive
                        )
                        editorContext = nil
                    },
                    onCancel: {
                        editorContext = nil
                    }
                )
            }
            .onAppear {
                print("RecurringExpensesView loaded")
                print("Loaded recurring expenses:", String(describing: viewModel.recurringExpenses))
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
        }
    }

    private var headerCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.recurringExpensesTitle)
                    .font(.system(size: 22 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.recurringExpensesSubtitle)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                Button {
                    editorContext = RecurringEditorContext(
                        recurringID: nil,
                        merchant: "",
                        amountText: "",
                        category: viewModel.categories.first ?? .other,
                        cadence: .monthly,
                        nextDueDate: .now,
                        isActive: true
                    )
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "repeat")
                        Text(strings.recurringExpensesCreateButton)
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var upcomingSummaryCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.recurringExpensesUpcomingTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text(strings.recurringExpensesUpcomingSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                if let first = viewModel.nextRecurringExpense {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(viewModel.recurringExpenseTitle(for: first))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(viewModel.recurringExpenseCadenceText(for: first.cadence))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Spacer()
                            Text(viewModel.displayCurrency(first.amount))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        Text(viewModel.recurringExpenseNextDueText(for: first))
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                } else {
                    Text(strings.recurringExpensesNoUpcomingMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func recurringExpenseCard(for recurring: RecurringExpense) -> some View {
        let statusText = recurring.isActive ? strings.recurringExpensesActiveLabel : strings.recurringExpensesInactiveLabel

        return GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.cardFill)
                        Image(systemName: "repeat")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.recurringExpenseTitle(for: recurring))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text("\(viewModel.recurringExpenseCadenceText(for: recurring.cadence)) • \(viewModel.displayCurrency(recurring.amount))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                        Text(viewModel.recurringExpenseNextDueText(for: recurring))
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
                    statusPill(text: statusText, tint: recurring.isActive ? Color(red: 0.19, green: 0.64, blue: 0.38) : AppTheme.tertiaryText)
                    statusPill(text: recurring.category.displayName, tint: recurring.category.accentColor)
                }

                HStack(spacing: 10) {
                    recurringActionButton(
                        title: strings.recurringExpensesEditButton,
                        systemImage: "pencil",
                        primary: false
                    ) {
                        editorContext = RecurringEditorContext(
                            recurringID: recurring.id,
                            merchant: recurring.merchant,
                            amountText: String(format: "%.2f", recurring.amount),
                            category: recurring.category,
                            cadence: recurring.cadence,
                            nextDueDate: recurring.nextDueDate,
                            isActive: recurring.isActive
                        )
                    }

                    recurringActionButton(
                        title: strings.recurringExpensesMarkPaidButton,
                        systemImage: "checkmark.circle.fill",
                        primary: false
                    ) {
                        viewModel.markRecurringAsPaid(id: recurring.id)
                    }

                    recurringActionButton(
                        title: strings.recurringExpensesDeleteButton,
                        systemImage: "trash",
                        primary: true
                    ) {
                        pendingRemovalRecurring = recurring
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func recurringActionButton(title: String, systemImage: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 14 * scale, weight: .semibold))
            .foregroundStyle(primary ? AppTheme.background : AppTheme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(primary ? AppTheme.primaryText : AppTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(primary ? Color.clear : AppTheme.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func statusPill(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.18))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}

private struct RecurringExpenseEditorView: View {
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    let recurringID: UUID?
    let initialMerchant: String
    let initialAmountText: String
    let initialCategory: ExpenseCategory
    let initialCadence: RecurringExpenseCadence
    let initialNextDueDate: Date
    let initialIsActive: Bool
    let categories: [ExpenseCategory]
    let onSave: (UUID?, String, Double, ExpenseCategory, RecurringExpenseCadence, Date, Bool) -> Void
    let onCancel: () -> Void

    @State private var merchantText: String
    @State private var amountText: String
    @State private var selectedCategory: ExpenseCategory
    @State private var selectedCadence: RecurringExpenseCadence
    @State private var nextDueDate: Date
    @State private var isActive: Bool
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case merchant
        case amount
    }

    init(
        recurringID: UUID?,
        initialMerchant: String,
        initialAmountText: String,
        initialCategory: ExpenseCategory,
        initialCadence: RecurringExpenseCadence,
        initialNextDueDate: Date,
        initialIsActive: Bool,
        categories: [ExpenseCategory],
        onSave: @escaping (UUID?, String, Double, ExpenseCategory, RecurringExpenseCadence, Date, Bool) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.recurringID = recurringID
        self.initialMerchant = initialMerchant
        self.initialAmountText = initialAmountText
        self.initialCategory = initialCategory
        self.initialCadence = initialCadence
        self.initialNextDueDate = initialNextDueDate
        self.initialIsActive = initialIsActive
        self.categories = categories
        self.onSave = onSave
        self.onCancel = onCancel
        _merchantText = State(initialValue: initialMerchant)
        _amountText = State(initialValue: initialAmountText)
        _selectedCategory = State(initialValue: initialCategory)
        _selectedCadence = State(initialValue: initialCadence)
        _nextDueDate = State(initialValue: initialNextDueDate)
        _isActive = State(initialValue: initialIsActive)
    }

    var body: some View {
        let scale = appTextSize.scale

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(strings.recurringExpensesEditorTitle)
                    .font(.system(size: 22 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                fieldSection(title: strings.recurringExpensesMerchantLabel) {
                    TextField(
                        "",
                        text: $merchantText,
                        prompt: Text(strings.recurringExpensesMerchantLabel)
                            .foregroundStyle(AppTheme.tertiaryText)
                    )
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .merchant)
                    .submitLabel(.next)
                    .font(.system(size: 16 * scale))
                    .foregroundColor(AppTheme.primaryText)
                    .tint(AppTheme.primaryText)
                    .accentColor(AppTheme.primaryText)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.inputFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(AppTheme.inputBorder, lineWidth: 1)
                            )
                    )
                }

                fieldSection(title: strings.recurringExpensesAmountLabel) {
                    TextField(
                        "",
                        text: $amountText,
                        prompt: Text("0.00")
                            .foregroundStyle(AppTheme.tertiaryText)
                    )
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .amount)
                    .font(.system(size: 26 * scale, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.primaryText)
                    .tint(AppTheme.primaryText)
                    .accentColor(AppTheme.primaryText)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.inputFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(AppTheme.inputBorder, lineWidth: 1)
                            )
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13 * scale))
                            .foregroundStyle(Color.red)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.recurringExpensesCategoryLabel)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 10)], spacing: 8) {
                        ForEach(categories) { category in
                            CategoryPillView(category: category, isSelected: selectedCategory == category)
                                .onTapGesture {
                                    selectedCategory = category
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.recurringExpensesCadenceLabel)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    Picker(strings.recurringExpensesCadenceLabel, selection: $selectedCadence) {
                        Text(strings.recurringCadenceDaily).tag(RecurringExpenseCadence.daily)
                        Text(strings.recurringCadenceWeekly).tag(RecurringExpenseCadence.weekly)
                        Text(strings.recurringCadenceMonthly).tag(RecurringExpenseCadence.monthly)
                        Text(strings.recurringCadenceYearly).tag(RecurringExpenseCadence.yearly)
                    }
                    .pickerStyle(.segmented)
                    .foregroundStyle(AppTheme.primaryText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.recurringExpensesNextDueLabel)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    DatePicker("", selection: $nextDueDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.primaryText)
                }

                Toggle(isOn: $isActive) {
                    Text(strings.recurringExpensesActiveLabel)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                .tint(AppTheme.primaryText)

                HStack(spacing: 12) {
                    Button(strings.cancel) {
                        onCancel()
                    }
                    .font(.system(size: 15 * scale, weight: .semibold))
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
                    .buttonStyle(.plain)

                    PrimaryButton(title: recurringID == nil ? strings.recurringExpensesCreateButton : strings.recurringExpensesSaveButton) {
                        let normalizedAmountText = amountText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                        guard let amount = Double(normalizedAmountText), amount.isFinite, amount > 0 else {
                            errorMessage = strings.recurringExpensesInvalidAmountError
                            return
                        }

                        onSave(
                            recurringID,
                            merchantText.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount,
                            selectedCategory,
                            selectedCadence,
                            nextDueDate,
                            isActive
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            focusedField = .amount
        }
        .onChange(of: merchantText) { _, _ in
            errorMessage = nil
        }
        .onChange(of: amountText) { _, _ in
            errorMessage = nil
        }
        .onChange(of: selectedCategory) { _, _ in
            errorMessage = nil
        }
        .onChange(of: selectedCadence) { _, _ in
            errorMessage = nil
        }
    }

    private func fieldSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13 * appTextSize.scale, weight: .semibold))
                .foregroundStyle(AppTheme.tertiaryText)
            content()
        }
    }
}
