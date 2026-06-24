import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    private var safeScale: CGFloat {
        let scale = appTextSize.scale
        return scale.isFinite && scale > 0 ? scale : 1
    }

    private enum EditorMode: String, Identifiable {
        case create
        case editWeekly
        case editMonthly

        var id: String { rawValue }
    }

    private var validWeeklyGoal: SpendingGoal? {
        sanitizedGoal(viewModel.weeklyGoal, expectedCadence: .weekly)
    }

    private var validMonthlyGoal: SpendingGoal? {
        sanitizedGoal(viewModel.monthlyGoal, expectedCadence: .monthly)
    }

    private var hasInvalidStoredGoal: Bool {
        [viewModel.weeklyGoal, viewModel.monthlyGoal].contains { goal in
            guard let goal else { return false }
            return !goal.isValid || !goal.createdAt.timeIntervalSinceReferenceDate.isFinite || !goal.updatedAt.timeIntervalSinceReferenceDate.isFinite
        }
    }

    @State private var editorMode: EditorMode?
    @State private var editorCadence: SpendingGoalCadence = .weekly
    @State private var editorLimitText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenHeaderView(
                    title: strings.goalsHeader,
                    subtitle: strings.goalsHeaderSubtitle,
                    showsSettingsButton: true
                )

                if hasInvalidStoredGoal {
                    warningCard
                }

                Button {
                    startCreateGoal()
                } label: {
                    actionPill(title: "Add Goal", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)

                if let goal = validWeeklyGoal {
                    goalCard(
                        title: strings.goalsWeeklyTitle,
                        periodLabel: strings.goalsPeriodThisWeek,
                        goal: goal,
                        spent: safeSpent(for: .weekly),
                        cadence: .weekly
                    )
                }

                if let goal = validMonthlyGoal {
                    goalCard(
                        title: strings.goalsMonthlyTitle,
                        periodLabel: strings.goalsPeriodThisMonth,
                        goal: goal,
                        spent: safeSpent(for: .monthly),
                        cadence: .monthly
                    )
                }

                if validWeeklyGoal == nil, validMonthlyGoal == nil {
                    EmptyStateView(
                        title: strings.goalsEmptyWeekly,
                        message: strings.goalsGoalLogicDescription
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .foregroundColor(AppTheme.primaryText)
        .tint(AppTheme.primaryText)
        .accentColor(AppTheme.primaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $editorMode) { mode in
            goalEditorSheet(mode: mode)
                .environment(\.pocketLeakStrings, strings)
                .environment(\.appTextSize, appTextSize)
        }
    }

    private func goalCard(
        title: String,
        periodLabel: String,
        goal: SpendingGoal,
        spent: Double,
        cadence: SpendingGoalCadence
    ) -> some View {
        let safeGoalLimit = safeGoalLimit(goal.limit)
        let safeSpent = safeAmount(spent)
        let remaining = max(safeGoalLimit - safeSpent, 0)
        let progress = safeProgress(spent: safeSpent, limit: safeGoalLimit)
        let statusText = goalStatusText(spent: safeSpent, limit: safeGoalLimit)
        let percentText = String(format: "%.0f%%", progress * 100)

        return GlassCardView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20 * safeScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(periodLabel)
                        .font(.system(size: 14 * safeScale))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                progressBar(progress: progress, statusText: statusText)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        metricCard(label: strings.goalsLimitLabel, value: viewModel.displayCurrency(safeGoalLimit))
                        metricCard(label: strings.goalsSpentLabel, value: viewModel.displayCurrency(safeSpent))
                    }
                    HStack(spacing: 10) {
                        metricCard(label: strings.goalsRemainingLabel, value: viewModel.displayCurrency(remaining))
                        metricCard(label: strings.goalsPercentUsedLabel, value: percentText)
                    }
                }

                Text(statusText)
                    .font(.system(size: 13 * safeScale))
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 10) {
                    Button {
                        startEditGoal(cadence: cadence, goal: goal)
                    } label: {
                        actionPill(title: "Edit Goal", systemImage: "pencil")
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        viewModel.removeGoal(cadence: cadence)
                    } label: {
                        actionPill(title: "Delete Goal", systemImage: "trash")
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func progressBar(progress: Double, statusText: String) -> some View {
        let safeProgress = progress.isFinite ? min(max(progress, 0), 1) : 0

        return GeometryReader { geometry in
            let width = max(geometry.size.width, 0)
            let fillWidth = max(0, min(width * safeProgress, width))

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppTheme.cardFill)
                Capsule(style: .continuous)
                    .fill(progressTint(for: safeProgress))
                    .frame(width: fillWidth)
            }
        }
        .frame(height: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(statusText)
        .accessibilityValue(statusText)
    }

    private func metricCard(label: String, value: String) -> some View {
        let safeLabel = label.isEmpty ? "—" : label
        let safeValue = value.isEmpty ? "—" : value

        return VStack(alignment: .leading, spacing: 4) {
            Text(safeLabel)
                .font(.system(size: 12 * safeScale))
                .foregroundStyle(AppTheme.tertiaryText)
            Text(safeValue)
                .font(.system(size: 16 * safeScale, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }

    private var warningCard: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Stored goal data needs attention")
                    .font(.system(size: 18 * safeScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text("Pocket Leak found old goal data that is not safe to render directly. It is preserved, and only valid goals are shown here.")
                    .font(.system(size: 13 * safeScale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func actionPill(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.system(size: 15 * safeScale, weight: .semibold))
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

    private func sanitizedGoal(_ goal: SpendingGoal?, expectedCadence: SpendingGoalCadence) -> SpendingGoal? {
        guard let goal else { return nil }
        guard goal.cadence == expectedCadence else { return nil }
        guard goal.isValid else { return nil }
        guard goal.createdAt.timeIntervalSinceReferenceDate.isFinite else { return nil }
        guard goal.updatedAt.timeIntervalSinceReferenceDate.isFinite else { return nil }
        return goal
    }

    private func safeAmount(_ amount: Double) -> Double {
        guard amount.isFinite, amount >= 0 else { return 0 }
        return amount
    }

    private func safeGoalLimit(_ limit: Double) -> Double {
        guard limit.isFinite, limit > 0 else { return 0 }
        return limit
    }

    private func safeProgress(spent: Double, limit: Double) -> Double {
        guard spent.isFinite, spent >= 0, limit.isFinite, limit > 0 else { return 0 }
        let progress = spent / limit
        guard progress.isFinite else { return 0 }
        return min(max(progress, 0), 1)
    }

    private func progressTint(for progress: Double) -> Color {
        if progress >= 1 {
            return Color(red: 0.86, green: 0.25, blue: 0.24)
        }
        if progress >= 0.75 {
            return Color(red: 0.92, green: 0.69, blue: 0.15)
        }
        return Color(red: 0.19, green: 0.64, blue: 0.38)
    }

    private func goalStatusText(spent: Double, limit: Double) -> String {
        let strings = AppStrings.current()
        let progress = safeProgress(spent: spent, limit: limit)
        if progress >= 1 {
            return strings.goalsStatusLimitReached
        }
        if progress >= 0.75 {
            return strings.goalsStatusCloseToLimit
        }
        if limit > 0 {
            return strings.goalsStatusOnTrack
        }
        return strings.goalsNoGoalStatus
    }

    private func safeSpent(for cadence: SpendingGoalCadence) -> Double {
        let value = viewModel.goalSpentAmount(for: cadence)
        return safeAmount(value)
    }

    private func startCreateGoal() {
        editorCadence = validWeeklyGoal == nil ? .weekly : .monthly
        editorLimitText = ""
        editorMode = .create
    }

    private func startEditGoal(cadence: SpendingGoalCadence, goal: SpendingGoal) {
        editorCadence = cadence
        editorLimitText = goal.limit.isFinite ? String(format: "%.2f", goal.limit) : ""
        editorMode = cadence == .weekly ? .editWeekly : .editMonthly
    }

    private func goalEditorSheet(mode: EditorMode) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goal Editor")
                        .font(.system(size: 22 * safeScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Create or edit a weekly or monthly spending goal.")
                        .font(.system(size: 14 * safeScale))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Picker("Cadence", selection: $editorCadence) {
                    Text(strings.goalsWeeklyTitle).tag(SpendingGoalCadence.weekly)
                    Text(strings.goalsMonthlyTitle).tag(SpendingGoalCadence.monthly)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.goalsLimitLabel)
                        .font(.system(size: 13 * safeScale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    TextField("0.00", text: $editorLimitText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .font(.system(size: 27 * safeScale, weight: .semibold, design: .rounded))
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

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("Goal Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        editorMode = nil
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveGoalFromEditor()
                    }
                }
            }
            .onAppear {
                if case .create = mode {
                    if validWeeklyGoal != nil, validMonthlyGoal == nil {
                        editorCadence = .monthly
                    } else if validWeeklyGoal == nil {
                        editorCadence = .weekly
                    }
                    if editorLimitText.isEmpty {
                        editorLimitText = ""
                    }
                }
            }
        }
    }

    private func saveGoalFromEditor() {
        guard let limit = Double(editorLimitText.replacingOccurrences(of: ",", with: ".")), limit.isFinite, limit > 0 else {
            return
        }
        viewModel.saveGoal(cadence: editorCadence, limit: limit)
        editorMode = nil
        editorLimitText = ""
    }
}
