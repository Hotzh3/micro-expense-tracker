# Roadmap

## Completed

- Product definition
- SwiftUI foundation
- Local persistence
- Manual pasted-text parsing
- Dashboard
- History
- Goals
- Insights
- Widgets
- Share Extension
- CSV export
- JSON export
- PDF export
- Demo Mode for safe portfolio data
- Performance cleanup for large local datasets

## In Progress

- README and portfolio documentation polish
- Screenshot and demo capture preparation
- Manual QA with synthetic demo data

## Next

- Final pass on visual presentation assets
- More manual iPhone validation with 1,000+ local expenses
- Release notes and repo topics cleanup
- Optional public-facing portfolio case study edits

## Future / Paid Distribution

- Apple Developer Program enrollment
- TestFlight distribution
- App Store submission materials
- App Store privacy nutrition details

## Future / Phase 8: Cloud + Social

Cloud and social features are intentionally documented as future work only. They are not required for the current local-first portfolio app.

### 8A Auth Strategy

- Decide whether the app should support anonymous local usage first
- Define the minimum identity model needed for sync and social features

### 8B Firebase vs CloudKit Decision

- Compare Firebase, CloudKit, and a hybrid approach
- Select the simplest architecture that matches the product scope

### 8C Personal Cloud Sync

- Sync a single user's local data across devices
- Preserve offline-first behavior and local editing

### 8D Multi-Device Sync

- Merge local changes across phone and tablet or multiple iPhones
- Define conflict handling and tombstones

### 8E Friend Circles

- Add private sharing groups
- Keep personal financial detail private by default

### 8F Privacy-Safe Leaderboard

- Share only relative progress, not raw expense data
- Surface goals, streaks, and spending discipline metrics

### 8G Challenges

- Optional savings or budget challenges between trusted groups
- No public social feed

### 8H Security / Privacy Audit

- Review data minimization, encryption, retention, and account recovery
- Re-check App Store privacy disclosures if distribution changes

### 8I Delete Account / Export Data

- Add permanent deletion controls
- Add portable export for user-owned data
