import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    @State private var selectedCadence: SpendingGoalCadence = .weekly
    @State private var limitText: String = ""
    @State private var pendingRemovalCadence: SpendingGoalCadence?
    @FocusState private var focusedField: Field?

    private var scale: CGFloat {
        appTextSize.scale
    }

    private enum Field {
        case limit
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenHeaderView(
                    title: strings.goalsHeader,
                    subtitle: strings.goalsHeaderSubtitle,
                    showsSettingsButton: true
                )

                VStack(spacing: 12) {
                    goalSection(for: .weekly)
                    goalSection(for: .monthly)
                }

                editorCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear(perform: syncEditorFromSelectedGoal)
        .onChange(of: selectedCadence) { _, _ in
            syncEditorFromSelectedGoal()
        }
        .onChange(of: viewModel.weeklyGoal) { _, _ in
            syncEditorFromSelectedGoal()
        }
        .onChange(of: viewModel.monthlyGoal) { _, _ in
            syncEditorFromSelectedGoal()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(strings.done) {
                    focusedField = nil
                }
            }
        }
        .confirmationDialog(
            strings.goalsRemoveConfirmationTitle,
            isPresented: Binding(
                get: { pendingRemovalCadence != nil },
                set: { if !$0 { pendingRemovalCadence = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(strings.goalsRemove, role: .destructive) {
                if let pendingRemovalCadence {
                    viewModel.removeGoal(cadence: pendingRemovalCadence)
                }
                pendingRemovalCadence = nil
                syncEditorFromSelectedGoal()
            }
            Button(strings.cancel, role: .cancel) {}
        } message: {
            Text(strings.goalsRemoveConfirmationMessage)
        }
    }

    private func goalSection(for cadence: SpendingGoalCadence) -> some View {
        let summary = viewModel.goalOverview(for: cadence)
        let emptyTitle = cadence == .weekly ? strings.goalsEmptyWeekly : strings.goalsEmptyMonthly
        let createTitle = cadence == .weekly ? strings.goalsCreateWeekly : strings.goalsCreateMonthly
        let sectionTitle = cadence == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle
        let periodLabel = cadence == .weekly ? strings.goalsPeriodThisWeek : strings.goalsPeriodThisMonth

        return GlassCardView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sectionTitle)
                            .font(.system(size: 20 * scale, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(periodLabel)
                            .font(.system(size: 14 * scale))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer(minLength: 0)

                    statusChip(for: cadence)
                }

                if let summary {
                    VStack(alignment: .leading, spacing: 12) {
                        progressBar(for: cadence)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            goalMetric(label: strings.goalsLimitLabel, value: summary.limitText)
                            goalMetric(label: strings.goalsSpentLabel, value: summary.spentText)
                            goalMetric(label: strings.goalsRemainingLabel, value: summary.remainingText)
                            goalMetric(label: strings.goalsPercentUsedLabel, value: viewModel.goalPercentUsedText(for: cadence))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            helperRow(
                                label: strings.goalsDaysLeftLabel,
                                value: viewModel.goalDaysLeftText(for: cadence)
                            )
                            helperRow(
                                label: strings.goalsRemainingDailyBudgetLabel,
                                value: viewModel.goalRemainingDailyBudgetText(for: cadence)
                            )

                            if cadence == .monthly {
                                helperRow(
                                    label: strings.goalsProjectedMonthSpendLabel,
                                    value: viewModel.goalProjectedMonthSpendText()
                                )
                            }
                        }

                        Text(summary.motivationText)
                            .font(.system(size: 14 * scale))
                            .foregroundStyle(AppTheme.secondaryText)

                        HStack(spacing: 10) {
                            Button {
                                selectedCadence = cadence
                                if let goal = viewModel.goal(for: cadence) {
                                    limitText = String(format: "%.2f", goal.limit)
                                }
                                focusedField = .limit
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                    Text(strings.goalsEdit)
                                }
                                .font(.system(size: 15 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryText)
                                .frame(maxWidth: .infinity)
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

                            Button {
                                pendingRemovalCadence = cadence
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text(strings.goalsRemove)
                                }
                                .font(.system(size: 15 * scale, weight: .semibold))
                                .foregroundStyle(AppTheme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppTheme.primaryText)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    EmptyStateView(title: emptyTitle, message: strings.goalsGoalLogicDescription)

                    Button {
                        selectedCadence = cadence
                        syncEditorFromSelectedGoal()
                        focusedField = .limit
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text(createTitle)
                        }
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.primaryText)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var editorCard: some View {
        let scale = appTextSize.scale
        let goal = viewModel.goal(for: selectedCadence)
        let actionTitle = goal == nil
            ? (selectedCadence == .weekly ? strings.goalsCreateWeekly : strings.goalsCreateMonthly)
            : strings.goalsEdit

        return GlassCardView {
            VStack(alignment: .leading, spacing: 14) {
                Text(strings.goalsEditorTitle)
                    .font(.system(size: 20 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Picker(strings.goalsEditorTitle, selection: $selectedCadence) {
                    ForEach(SpendingGoalCadence.allCases) { cadence in
                        Text(cadence == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle).tag(cadence)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.goalsLimitLabel)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    TextField("0.00", text: $limitText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .limit)
                        .font(.system(size: 27 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppTheme.cardFill)
                        )
                }

                PrimaryButton(title: actionTitle) {
                    guard let limit = Double(limitText.replacingOccurrences(of: ",", with: ".")), limit > 0 else { return }
                    viewModel.saveGoal(cadence: selectedCadence, limit: limit)
                }

                Text(strings.goalsGoalLogicDescription)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statusChip(for cadence: SpendingGoalCadence) -> some View {
        let status = viewModel.goalStatusText(for: cadence)
        let fill: Color

        switch viewModel.goalStatus(for: cadence) {
        case .onTrack:
            fill = AppTheme.primaryText.opacity(0.12)
        case .closeToLimit:
            fill = Color.yellow.opacity(0.18)
        case .limitReached:
            fill = Color.red.opacity(0.18)
        case .none:
            fill = AppTheme.chipFill
        }

        return Text(status)
            .font(.system(size: 13 * appTextSize.scale, weight: .semibold))
            .foregroundStyle(AppTheme.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(fill)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
    }

    private func progressBar(for cadence: SpendingGoalCadence) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppTheme.cardFill)
                Capsule(style: .continuous)
                    .fill(progressFill(for: cadence))
                    .frame(width: max(12, geometry.size.width * viewModel.goalProgressFraction(for: cadence)))
            }
        }
        .frame(height: 14)
    }

    private func helperRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13 * appTextSize.scale))
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 13 * appTextSize.scale, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }

    private func progressFill(for cadence: SpendingGoalCadence) -> Color {
        switch viewModel.goalStatus(for: cadence) {
        case .onTrack:
            return AppTheme.primaryText
        case .closeToLimit:
            return Color.orange
        case .limitReached:
            return Color.red
        case .none:
            return AppTheme.primaryText
        }
    }

    private func goalMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12 * appTextSize.scale))
                .foregroundStyle(AppTheme.tertiaryText)
            Text(value)
                .font(.system(size: 16 * appTextSize.scale, weight: .semibold))
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

    private func syncEditorFromSelectedGoal() {
        guard let goal = viewModel.goal(for: selectedCadence) else {
            limitText = ""
            return
        }

        limitText = String(format: "%.2f", goal.limit)
    }
}
