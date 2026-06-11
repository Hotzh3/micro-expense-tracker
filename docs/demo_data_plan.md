# Demo Data Plan

Use this local-only dataset for screenshots, recorded demos, and portfolio walkthroughs.

## Goals

- Make Dashboard feel complete with multiple categories, active goals, visible budgets, and upcoming recurring expenses.
- Keep the dataset synthetic and clearly separated from real user spending.
- Support fast reset so the app can switch back to a clean local state after a demo session.

## What Demo Mode Generates

- 45 days of expenses
- Multiple expenses per day with weekend and weekday variation
- Categories:
  - Coffee
  - Food
  - Transport
  - Shopping
  - Entertainment
  - Convenience
  - Other for health-style merchants
- Realistic merchants:
  - Starbucks
  - Café Central
  - OXXO
  - 7-Eleven
  - Uber
  - Didi
  - Metro
  - Rappi
  - Toks
  - Taqueria El Paraiso
  - Walmart
  - Amazon
  - Liverpool
  - Cinépolis
  - Netflix
  - Spotify
  - Farmacia San Pablo
  - Clínica Vida
  - GymFit
- Weekly and monthly goals
- Category budgets with safe, watch, and over states
- Upcoming recurring expenses

## Safety Rules

- Demo expenses are marked with `ExpenseSource.demo`.
- Demo data is synthetic only.
- Demo mode is not enabled automatically on launch.
- Loading demo data replaces current local data after confirmation.
- Reset Demo Data removes only demo-tagged content when the saved demo manifest exists.
- If the manifest is missing, the UI falls back to a full local clear after a second confirmation.

## Reset Behavior

- `Load Demo Data`:
  - Replaces current expenses, goals, category budgets, and recurring expenses.
  - Saves a local demo manifest with the generated IDs.
- `Reset Demo Data`:
  - Removes expenses with `source == .demo`.
  - Removes demo goals, category budgets, and recurring expenses using the manifest.
  - If the manifest is missing, the app asks for confirmation before clearing all local data.
- `Clear All Data`:
  - Deletes all local expenses, goals, budgets, recurring expenses, and demo metadata.

## Recommended Demo Targets

- Dashboard:
  - Donut chart with several visible slices
  - Trend chart with movement
  - Recent expenses list with a few rows only
  - Goal, budget, and recurring highlights visible at once
- History:
  - At least 100 visible rows available for scrolling
  - Filters still work with the synthetic dataset
- Goals:
  - Weekly goal near the watch zone
  - Monthly goal with visible remaining budget
- Insights:
  - Category breakdowns and averages show meaningful values

## Sample Parse Text Inputs

- `Compra por $140 en OXXO`
- `BBVA: Compra aprobada por $85.50 en STARBUCKS`
- `NU: UBER TRIP MXN 65`
- `$1,299.00 Amazon`
- `Pago en Restaurante Toks 430.00 MXN`

