# Cloud + Social Roadmap

Pocket Leak is deliberately local-first today. Cloud and social features belong in a later phase only if they clearly improve the product without harming privacy, simplicity, or offline use.

## Why Cloud Later

- multi-device sync becomes useful once the local experience is stable
- some users will eventually want the same data on an iPhone, iPad, or replacement device
- private sharing can make goals, challenges, and accountability features more useful
- cloud can reduce manual restore friction once there is a mature export/import story

## Why Not Now

- the current product goal is a strong local-first portfolio app
- cloud adds identity, sync conflicts, retention, and account recovery complexity
- finance apps need a very careful privacy story before remote storage is introduced
- the current scope does not justify platform or backend overhead
- local UX, performance, and documentation still have more value than remote features right now

## Risks

- data model changes can break local persistence and existing exports
- identity and privacy requirements can expand scope quickly
- social features can accidentally expose sensitive behavior
- sync conflicts can create trust issues if the merge strategy is unclear
- cloud services can introduce ongoing cost and operational maintenance

## Benefits

- data can follow the user to a new device
- backups and restores can become smoother
- private sharing can enable friend circles and challenges
- leaderboard-style motivation can work without exposing raw transactions
- future distribution options can improve if the app eventually goes public

## Suggested Future Phases

### 8A Auth Strategy

- choose the identity model before choosing a backend
- decide whether anonymous local usage remains the default
- define account lifecycle, recovery, and logout behavior

### 8B Firebase vs CloudKit Decision

- compare the minimum product needed for the roadmap
- select the backend only after privacy and platform constraints are understood
- avoid overbuilding for cross-platform support unless it is truly needed

### 8C Personal Cloud Sync

- sync one user's own devices first
- keep local-first behavior as the default
- make sync opt-in and reversible

### 8D Multi-Device Sync

- support a second device without requiring manual file transfer
- define merge rules, conflict resolution, and replay protection

### 8E Friend Circles

- allow trusted private groups
- keep the sharing model limited to safe progress metrics

### 8F Privacy-Safe Leaderboard

- share only relative metrics
- never expose raw expense lines by default

### 8G Challenges

- add optional accountability loops
- focus on streaks, limits, and percent-of-goal usage

### 8H Security / Privacy Audit

- review data minimization
- verify access control, deletion, retention, and recovery
- update privacy disclosures if the app ever leaves local-only mode

### 8I Delete Account / Export Data

- support permanent deletion
- support user-owned portable export
- make data removal and migration explicit

## Decision Criteria Before Starting Phase 8

- local product usage is stable
- the data model is stable enough for sync identifiers and tombstones
- export/import is reliable
- privacy labeling implications are understood
- the feature set justifies account management overhead
