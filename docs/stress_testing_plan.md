# Stress Testing Plan

Goal: validate that Pocket Leak stays stable and responsive when it stores 1 to 2 months or more of local synthetic spending.

## Objective

- Confirm launch remains stable with large local datasets.
- Confirm Dashboard, History, Goals, Insights, Backup, Widgets, and Settings remain usable after prolonged usage.
- Find layout or performance regressions before they become release blockers.

## Scenarios

### Data Volume Scenarios

- 30 days of data with 3 expenses per day
- 30 days of data with 5 expenses per day
- 60 days of data with 10 expenses per day
- 90 days of data with 20 expenses per day
- 180 days of data with 30 expenses per day
- 365 days of data with 10 expenses per day

### Functional Stress Scenarios

- Repeated app launch / relaunch
- Dashboard opens with large data sets
- History search and filters on large data sets
- Goals and budgets with many historical expenses
- Backup export and import after large data generation
- Widgets reading the local summary after large data generation

## How To Run Tests

1. Run the unit test suite.
2. Use the DEBUG `Stress / Demo Tools` section in Settings to generate synthetic expense history.
3. Open Dashboard, History, Goals, Insights, and Settings repeatedly.
4. Use Demo Mode or the DEBUG stress tools to generate synthetic history.
5. Export backup or CSV / JSON data if available in the build.
6. Measure whether the app stays responsive after relaunching.

## Manual iPhone Checks

- Open the app cold.
- Generate 30, 60, or 90 days of synthetic data in DEBUG.
- Confirm Dashboard still opens quickly.
- Confirm History search and filters remain responsive.
- Confirm Goals still open and save correctly.
- Confirm export still works.
- Confirm widgets still load summary data.
- Confirm no crash loop after backgrounding and reopening the app.

## What To Watch

- Launch time
- Dashboard speed
- History speed
- Goals stability
- Export speed
- Widget rendering
- Memory growth
- Scroll performance
- Layout warnings

## Notes

- Do not use real or sensitive financial data for stress tests.
- Do not connect to any network service.
- Keep the stress harness local and deterministic.
- Prefer synthetic demo data or generated stress data over manual hand-entered records.
