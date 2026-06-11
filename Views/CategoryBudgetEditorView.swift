import SwiftUI

struct CategoryBudgetEditorView: View {
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    let budgetID: UUID?
    let initialCategory: ExpenseCategory
    let initialCadence: SpendingGoalCadence
    let initialLimitText: String
    let categories: [ExpenseCategory]
    let onSave: (UUID?, ExpenseCategory, SpendingGoalCadence, Double) -> Void
    let onCancel: () -> Void

    @State private var selectedCategory: ExpenseCategory
    @State private var selectedCadence: SpendingGoalCadence
    @State private var limitText: String
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case limit
    }

    init(
        budgetID: UUID?,
        initialCategory: ExpenseCategory,
        initialCadence: SpendingGoalCadence,
        initialLimitText: String,
        categories: [ExpenseCategory],
        onSave: @escaping (UUID?, ExpenseCategory, SpendingGoalCadence, Double) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.budgetID = budgetID
        self.initialCategory = initialCategory
        self.initialCadence = initialCadence
        self.initialLimitText = initialLimitText
        self.categories = categories
        self.onSave = onSave
        self.onCancel = onCancel
        _selectedCategory = State(initialValue: initialCategory)
        _selectedCadence = State(initialValue: initialCadence)
        _limitText = State(initialValue: initialLimitText)
    }

    var body: some View {
        let scale = appTextSize.scale

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(strings.categoryBudgetsEditorTitle)
                    .font(.system(size: 22 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.categoryBudgetsCategoryLabel)
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
                    Text(strings.categoryBudgetsCadenceLabel)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    Picker(strings.categoryBudgetsCadenceLabel, selection: $selectedCadence) {
                        Text(strings.goalsWeeklyTitle).tag(SpendingGoalCadence.weekly)
                        Text(strings.goalsMonthlyTitle).tag(SpendingGoalCadence.monthly)
                    }
                    .pickerStyle(.segmented)
                    .foregroundStyle(AppTheme.primaryText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.categoryBudgetsLimitLabel)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    TextField("0.00", text: $limitText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .limit)
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

                    PrimaryButton(title: budgetID == nil ? strings.categoryBudgetsCreateButton : strings.categoryBudgetsSaveButton) {
                        guard let limit = Double(limitText.replacingOccurrences(of: ",", with: ".")), limit.isFinite, limit > 0 else {
                            errorMessage = strings.categoryBudgetsInvalidLimitError
                            return
                        }

                        onSave(budgetID, selectedCategory, selectedCadence, limit)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            focusedField = .limit
        }
        .onChange(of: selectedCategory) { _, _ in
            errorMessage = nil
        }
        .onChange(of: selectedCadence) { _, _ in
            errorMessage = nil
        }
        .onChange(of: limitText) { _, _ in
            errorMessage = nil
        }
    }
}
