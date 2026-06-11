# Social Privacy Model

If Pocket Leak ever adds friend circles or challenges, the default social model must avoid exposing raw spending data.

## Do Not Share By Default

- exact expense amounts
- merchants
- notes
- full history
- category labels that may reveal sensitive behavior
- recurring subscription details

## Safe To Share

- percentage of goal used
- points or streak score
- days within budget
- badges
- relative ranking
- challenge completion status

## Example Leaderboard

The leaderboard should use relative metrics only:

- Ana: 42% of meta used
- José: 63%
- Carlos: 91%

This communicates progress without revealing the underlying expenses.

## Privacy Rules

- social sharing should be opt-in
- the user should choose which circle sees which metric
- personal transactions stay private unless the user explicitly exports or shares them
- default views should never expose merchants or notes in a social surface
- leaderboards should avoid raw monetary comparisons when possible and prefer normalized progress metrics

## Good Social Signals

- budget streaks
- goal progress
- challenge completion
- savings consistency
- on-time recurring handling

## Bad Social Signals

- raw merchant names
- transaction notes
- exact itemized expenses
- full timestamp histories
- private category breakdowns unless the user explicitly opts in

## Principle

Share encouragement, not the spending ledger.
