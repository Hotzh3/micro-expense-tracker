import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @FocusState private var focusedField: Field?
    @State private var captureMode: CaptureMode = .today
    @State private var pastDate = Date.now

    private var scale: CGFloat {
        let value = appTextSize.scale
        return value.isFinite && value > 0 ? value : 1
    }

    private var strings: AppStrings {
        AppStrings.current()
    }

    enum Field {
        case amount
        case merchant
        case note
    }

    enum CaptureMode: String, CaseIterable, Identifiable {
        case today
        case pastDate

        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                quickAddContent
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 18)
            }
            .scrollDismissesKeyboard(.interactively)
            .foregroundColor(AppTheme.primaryText)
            .tint(AppTheme.primaryText)
            .accentColor(AppTheme.primaryText)
            .animation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.quick), value: viewModel.saveFeedback)
            .onChange(of: focusedField) { _, newValue in
                viewModel.isQuickAddInputFocused = newValue != nil
            }
            .onAppear {
                viewModel.isQuickAddInputFocused = focusedField != nil
                if captureMode == .today {
                    focusedField = .amount
                }
            }
            .onDisappear {
                viewModel.isQuickAddInputFocused = false
            }
            .onChange(of: viewModel.quickAddRouteToken) { _, _ in
                captureMode = .today
                pastDate = .now
                focusedField = .amount
            }
            .onChange(of: viewModel.amountText) { _, _ in viewModel.clearSaveFeedback() }
            .onChange(of: viewModel.merchantText) { _, _ in viewModel.clearSaveFeedback() }
            .onChange(of: viewModel.noteText) { _, _ in viewModel.clearSaveFeedback() }
            .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.clearSaveFeedback() }

            if viewModel.saveFeedback != nil {
                HStack {
                    Spacer(minLength: 0)
                    if let saveFeedback = viewModel.saveFeedback {
                        saveToast(for: saveFeedback)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
                .transition(AppMotion.transition(reduceMotion: reduceMotion))
                .allowsHitTesting(false)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                switch focusedField {
                case .amount:
                    Spacer()
                    Button(strings.next) {
                        focusedField = .merchant
                    }
                case .merchant:
                    Button(strings.done) {
                        focusedField = nil
                    }
                    Spacer()
                    Button(strings.next) {
                        focusedField = .note
                    }
                case .note:
                    Button(strings.done) {
                        focusedField = nil
                    }
                    Spacer()
                case .none:
                    Spacer()
                    Button(strings.done) {
                        focusedField = nil
                    }
                }
            }
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings.amountTitle)
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.tertiaryText)

            TextField(
                "",
                text: $viewModel.amountText,
                prompt: Text("0.00")
                    .foregroundStyle(AppTheme.tertiaryText)
            )
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)
                .submitLabel(.next)
                .font(.system(size: 40 * scale, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.primaryText)
                .tint(AppTheme.primaryText)
                .accentColor(AppTheme.primaryText)
                .accessibilityLabel(strings.amountTitle)
                .accessibilityHint(strings.saveMissingAmountError)
                .padding(.vertical, 12)
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
        .id(Field.amount)
    }

    private var quickAddContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScreenHeaderView(
                title: strings.quickAddHeader,
                subtitle: strings.quickAddIntro,
                showsSettingsButton: true
            )

            captureModeCard
            amountCard
            if captureMode == .pastDate {
                pastDateCard
            }
            categoryCard
            detailsCard
            saveExpenseButton
        }
    }

    private var captureModeCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Capture mode")
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Picker("Capture mode", selection: $captureMode) {
                    Text("Today").tag(CaptureMode.today)
                    Text("Past Date").tag(CaptureMode.pastDate)
                }
                .pickerStyle(.segmented)
                .onChange(of: captureMode) { _, newValue in
                    if newValue == .today {
                        pastDate = .now
                    } else {
                        pastDate = min(pastDate, .now)
                    }
                }

                Text(captureMode == .today ? "Save expenses for today." : "Choose a previous date for this expense.")
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var amountCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.quickAddIntro)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                amountField
            }
        }
    }

    private var pastDateCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Expense date")
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                DatePicker(
                    "Expense date",
                    selection: pastDateBinding,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                Text("Future dates are blocked to keep your history accurate.")
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var categoryCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.categoryTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Text(strings.categorySubtitle)
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(AppTheme.secondaryText)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 10)], spacing: 8) {
                    ForEach(viewModel.categories) { category in
                        categoryPill(for: category)
                    }
                }
            }
        }
    }

    private var detailsCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.detailsTitle)
                    .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                TextField(
                    "",
                    text: $viewModel.merchantText,
                    prompt: Text(strings.merchantPlaceholder)
                        .foregroundStyle(AppTheme.tertiaryText)
                )
                    .id(Field.merchant)
                    .textFieldStyle(.plain)
                    .foregroundColor(AppTheme.primaryText)
                    .tint(AppTheme.primaryText)
                    .accentColor(AppTheme.primaryText)
                    .focused($focusedField, equals: .merchant)
                    .submitLabel(.next)
                    .font(.system(size: 15 * scale))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 14)
                    .accessibilityLabel(strings.merchantPlaceholder)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.inputFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.inputBorder, lineWidth: 1)
                            )
                    )

                TextField(
                    "",
                    text: $viewModel.noteText,
                    prompt: Text(strings.notePlaceholder)
                        .foregroundStyle(AppTheme.tertiaryText)
                )
                    .id(Field.note)
                    .textFieldStyle(.plain)
                    .foregroundColor(AppTheme.primaryText)
                    .tint(AppTheme.primaryText)
                    .accentColor(AppTheme.primaryText)
                    .focused($focusedField, equals: .note)
                    .submitLabel(.done)
                    .font(.system(size: 15 * scale))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 14)
                    .accessibilityLabel(strings.notePlaceholder)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.inputFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.inputBorder, lineWidth: 1)
                            )
                )
            }
        }
    }

    private func categoryPill(for category: ExpenseCategory) -> some View {
        CategoryPillView(category: category, isSelected: viewModel.selectedCategory == category)
            .onTapGesture {
                selectCategory(category)
            }
    }

    private var saveExpenseButton: some View {
        PrimaryButton(title: strings.saveExpenseButton) {
            viewModel.saveDraftExpense(date: selectedExpenseDate)
            resetDateAfterSaveIfNeeded()
        }
        .accessibilityLabel(strings.saveExpenseButton)
        .accessibilityHint(strings.saveMissingAmountError)
    }

    private var selectedExpenseDate: Date {
        captureMode == .today ? .now : pastDate
    }

    private func selectCategory(_ category: ExpenseCategory) {
        guard viewModel.selectedCategory != category else { return }
        HapticsService.shared.lightTap()
        viewModel.selectedCategory = category
    }

    private func saveToast(for feedback: ExpenseViewModel.Feedback) -> some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(feedback.isError ? Color.red : Color.green)
            Text(feedback.message)
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(feedback.isError ? Color.red.opacity(0.14) : Color.green.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(feedback.isError ? Color.red.opacity(0.42) : Color.green.opacity(0.48), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 10)
        .frame(maxWidth: .infinity, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(feedback.isError ? strings.needsAttention : strings.ready)
        .accessibilityValue(feedback.message)
    }

    private var pastDateBinding: Binding<Date> {
        Binding(
            get: { min(pastDate, .now) },
            set: { newValue in
                pastDate = min(newValue, .now)
            }
        )
    }

    private func resetDateAfterSaveIfNeeded() {
        guard captureMode == .pastDate else { return }
        pastDate = .now
    }
}
