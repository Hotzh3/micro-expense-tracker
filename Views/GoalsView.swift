import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var viewModel: ExpenseViewModel
    @Environment(\.pocketLeakStrings) private var strings: AppStrings
    @Environment(\.appTextSize) private var appTextSize: AppTextSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedCadence: SpendingGoalCadence = .weekly
    @State private var limitText: String = ""
    @State private var pendingRemovalCadence: SpendingGoalCadence?
    @State private var didAnimateIn = false
    @FocusState private var focusedField: Field?

    private var scale: CGFloat {
        appTextSize.scale
    }

    private enum Field {
        case limit
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
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
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 8)

                    editorCard
                        .id("goal-editor")
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .foregroundColor(AppTheme.primaryText)
            .tint(AppTheme.primaryText)
            .accentColor(AppTheme.primaryText)
            .onChange(of: focusedField) { _, newValue in
                viewModel.isGoalsInputFocused = newValue != nil
                guard newValue != nil else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    scrollProxy.scrollTo("goal-editor", anchor: .center)
                }
            }
            .onAppear {
                viewModel.isGoalsInputFocused = focusedField != nil
            }
            .onDisappear {
                viewModel.isGoalsInputFocused = false
            }
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
        .onAppear {
            print("GoalsView loaded")
            print("Loaded goals:", String(describing: viewModel.weeklyGoal), String(describing: viewModel.monthlyGoal))
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
        let emptyTitle = cadence == .weekly ? strings.goalsEmptyWeekly : strings.goalsEmptyMonthly
        let createTitle = cadence == .weekly ? strings.goalsCreateWeekly : strings.goalsCreateMonthly
        let sectionTitle = cadence == .weekly ? strings.goalsWeeklyTitle : strings.goalsMonthlyTitle
        let periodLabel = cadence == .weekly ? strings.goalsPeriodThisWeek : strings.goalsPeriodThisMonth
        let goal = viewModel.goal(for: cadence)
        let summary = viewModel.goalOverview(for: cadence)
        let hasGoal = goal != nil
        let safeLimitText = summary?.limitText ?? "$0.00"
        let safeSpentText = summary?.spentText ?? "$0.00"
        let safeRemainingText = summary?.remainingText ?? "$0.00"
        let safePercentText = viewModel.goalPercentUsedText(for: cadence)
        let safeStatusText = viewModel.goalStatusText(for: cadence)
        let goalStatus = viewModel.goalStatus(for: cadence)
        let progressFillColor = progressFill(for: goalStatus)
        let progress = viewModel.goalProgressFraction(for: cadence)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )

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

                    statusChip(statusText: safeStatusText, fill: statusChipFill(for: goalStatus))
                }

                if hasGoal {
                    VStack(alignment: .leading, spacing: 12) {
                        progressBar(progress: progress, fill: progressFillColor, statusText: safeStatusText, hasGoal: hasGoal)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            goalMetric(label: strings.goalsLimitLabel, value: safeLimitText)
                            goalMetric(label: strings.goalsSpentLabel, value: safeSpentText)
                            goalMetric(label: strings.goalsRemainingLabel, value: safeRemainingText)
                            goalMetric(label: strings.goalsPercentUsedLabel, value: safePercentText)
                        }

                        HStack(spacing: 10) {
                            goalActionButton(
                                title: strings.goalsEdit,
                                systemImage: "pencil",
                                primary: false
                            ) {
                                selectedCadence = cadence
                                limitText = goal.map { String(format: "%.2f", $0.limit) } ?? ""
                                focusedField = .limit
                            }

                            goalActionButton(
                                title: strings.goalsRemove,
                                systemImage: "trash",
                                primary: true
                            ) {
                                pendingRemovalCadence = cadence
                            }
                        }
                    }
                } else {
                    EmptyStateView(title: emptyTitle, message: strings.goalsGoalLogicDescription)

                    goalActionButton(
                        title: createTitle,
                        systemImage: "plus.circle.fill",
                        primary: true
                    ) {
                        selectedCadence = cadence
                        limitText = ""
                        focusedField = .limit
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
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
                .accessibilityLabel(strings.goalsEditorTitle)

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.goalsLimitLabel)
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)

                    TextField("0.00", text: $limitText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .limit)
                        .font(.system(size: 27 * scale, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.primaryText)
                        .tint(AppTheme.primaryText)
                        .accentColor(AppTheme.primaryText)
                        .accessibilityLabel(strings.goalsLimitLabel)
                        .accessibilityHint(strings.goalsGoalLogicDescription)
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

                PrimaryButton(title: actionTitle) {
                    guard let limit = Double(limitText.replacingOccurrences(of: ",", with: ".")), limit.isFinite, limit > 0 else {
                        print("Invalid goal ignored:", limitText)
                        return
                    }
                    print("Saving \(selectedCadence.rawValue) goal:", limit)
                    viewModel.saveGoal(cadence: selectedCadence, limit: limit)
                }

                Text(strings.goalsGoalLogicDescription)
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statusChip(statusText: String, fill: Color) -> some View {
        Text(statusText)
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

    private func statusChipFill(for status: ExpenseViewModel.GoalStatus) -> Color {
        switch status {
        case .onTrack:
            return Color(red: 0.19, green: 0.64, blue: 0.38).opacity(0.18)
        case .closeToLimit:
            return Color(red: 0.92, green: 0.69, blue: 0.15).opacity(0.18)
        case .limitReached:
            return Color(red: 0.86, green: 0.25, blue: 0.24).opacity(0.18)
        case .none:
            return AppTheme.chipFill
        }
    }

    private func progressBar(progress: Double, fill: Color, statusText: String, hasGoal: Bool) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppTheme.cardFill)
                Capsule(style: .continuous)
                    .fill(fill)
                    .frame(width: max(12, geometry.size.width * progress))
                    .animation(AppMotion.animation(reduceMotion: reduceMotion, fallback: AppMotion.emphasis), value: progress)
            }
        }
        .frame(height: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(hasGoal ? statusText : strings.goalsNoGoalStatus)
        .accessibilityValue(hasGoal ? statusText : strings.goalsNoGoalMessage)
    }

    private func goalActionButton(
        title: String,
        systemImage: String,
        primary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 15 * scale, weight: .semibold))
            .foregroundStyle(primary ? AppTheme.background : AppTheme.primaryText)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(primary ? AppTheme.primaryText : AppTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(primary ? Color.clear : AppTheme.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func progressFill(for status: ExpenseViewModel.GoalStatus) -> Color {
        switch status {
        case .onTrack:
            return Color(red: 0.19, green: 0.64, blue: 0.38)
        case .closeToLimit:
            return Color(red: 0.92, green: 0.69, blue: 0.15)
        case .limitReached:
            return Color(red: 0.86, green: 0.25, blue: 0.24)
        case .none:
            return Color(red: 0.19, green: 0.64, blue: 0.38)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func syncEditorFromSelectedGoal() {
        guard let goal = viewModel.goal(for: selectedCadence) else {
            limitText = ""
            return
        }

        limitText = String(format: "%.2f", goal.limit)
    }
}
