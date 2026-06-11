# Performance Notes

## What Was Optimized

- Centralized expense-derived calculations inside `ExpenseViewModel` with a cached analytics snapshot.
- Added `DashboardSummary` and `HistorySummary` helpers so the views consume precomputed totals, breakdowns, and limited recent rows.
- Reused shared formatters through `Services/PocketLeakFormatters.swift` to avoid creating new `DateFormatter`, `ISO8601DateFormatter`, and `NumberFormatter` instances in hot paths.
- Reduced repeated work in Dashboard, History, Goals, Insights, the weekly digest card, PDF export, CSV/JSON export, backup export, and the widget.
- Changed the dashboard recent activity section to a small cached list instead of sorting the full expense array in `body`.
- Switched history filtering to compute the filtered list, total, and count once per filter state.
- Kept the widget progress math finite-safe and removed repeated max calculations per row.

## What Remains

- The app still recomputes some secondary summaries on demand, such as export payloads and PDF report data, because those are user-triggered paths rather than render paths.
- `GeometryReader` remains in a few intentional layout spots, including the goals progress bar and the widget’s small category bars.
- Performance should still be checked on-device with large local datasets once simulator/runtime availability is normal.

## Limits Tested

- `xcodegen generate` completed successfully.
- `xcodebuild` Debug reached asset compilation but was blocked by the local simulator/runtime environment.
- `xcodebuild` Release reached the app targets and then failed at the same asset-catalog simulator runtime limitation.
- `xcodebuild test` could not start because the requested `iPhone 16` simulator was unavailable.
- The Release pass did surface one real code issue in the widget `largeView` return path; that was fixed and rechecked.

## Recommendations

- Re-run Debug, Release, and tests on a Mac with working simulator runtimes before considering the cleanup done.
- Stress-test with at least 1,000 local expenses and verify Dashboard, History, Goals, Insights, share card generation, PDF export, and backup export separately.
- Keep future performance work inside cached summary helpers rather than adding more per-view filtering and sorting.
