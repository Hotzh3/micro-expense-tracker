# Performance Baseline

Use this table to record the local performance profile of Pocket Leak as the dataset grows.

| Scenario | Expense Count | App Opens? | Dashboard Opens? | History Filters? | Export Works? | Notes |
|---|---:|---|---|---|---|---|
| Fresh install | 0 | TBD | TBD | TBD | TBD | Baseline clean state |
| 30 days x 5/day | 150 | TBD | TBD | TBD | TBD | Generated stress demo |
| 60 days x 10/day | 600 | TBD | TBD | TBD | TBD | Medium-large local dataset |
| 90 days x 20/day | 1,800 | TBD | TBD | TBD | TBD | Heavy local dataset |
| 365 days x 10/day | 3,650 | TBD | TBD | TBD | TBD | Long-term daily usage simulation |

## Baseline Notes

- Fill this table after each iPhone QA pass.
- Record any launch delay, scrolling lag, or export slowdown.
- Add comments if Dashboard, History, or Goals regress as data grows.

## Phase 7B Cleanup

- Centralized expense analytics in `ExpenseViewModel` so Dashboard, History, Goals, Insights, and exports read cached summaries instead of re-filtering the full expense list on every render.
- Moved repeated formatters into `Services/PocketLeakFormatters.swift` and reused them in CSV, JSON, PDF, backup, share cards, history rows, and weekly digest date labels.
- Reduced repeated work in `HistoryView`, `GoalsView`, `DashboardView`, and the widget by reusing local summaries and limiting recent activity lists.
- Switched the dashboard recent expenses section to a cached, limited list and changed the history summary path to compute filtered totals once per filter state.
- Kept export and backup paths local-only. No cloud, login, or social features were added.

## Portfolio Notes

- The app is meant to look good in screenshots and also remain responsive with large local histories.
- Demo Mode exists so marketing and portfolio captures can use synthetic data instead of private spending.
- Current documentation work is focused on making the repository easy to understand from the README alone.

## Validation Status

- Debug build attempted: blocked by local `actool`/simulator runtime availability in this environment.
- Release build attempted: compile reached the app targets and then failed at the same asset-catalog simulator runtime limitation.
- Test run attempted: blocked because the requested `iPhone 16` simulator is not available in this environment.
