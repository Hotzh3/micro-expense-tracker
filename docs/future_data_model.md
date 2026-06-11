# Future Data Model

This is a future model for Phase 8 cloud and social work. It is intentionally not implemented yet.

## Core Entities

### users

- `id`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `deviceId`
- `schemaVersion`
- `pendingSync`
- optional profile metadata if the user opts into an account

### expenses

- `id`
- `userId`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `deviceId`
- `schemaVersion`
- `pendingSync`
- `amount`
- `currencyCode`
- `category`
- `merchant`
- `note`
- `date`

### goals

- `id`
- `userId`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `deviceId`
- `schemaVersion`
- `pendingSync`
- `type`
- `targetAmount`
- `period`
- `startDate`
- `endDate`

### categoryBudgets

- `id`
- `userId`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `deviceId`
- `schemaVersion`
- `pendingSync`
- `category`
- `budgetAmount`
- `period`

### recurringExpenses

- `id`
- `userId`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `deviceId`
- `schemaVersion`
- `pendingSync`
- `merchant`
- `amount`
- `frequency`
- `nextDueDate`

### circles

- `id`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `schemaVersion`
- `pendingSync`
- `name`
- `privacyLevel`

### circleMembers

- `id`
- `circleId`
- `userId`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `schemaVersion`
- `pendingSync`
- `role`

### leaderboardStats

- `id`
- `userId`
- `circleId`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `schemaVersion`
- `pendingSync`
- `period`
- `goalProgressPercent`
- `budgetStreak`
- `points`
- `rank`

### challenges

- `id`
- `circleId`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `schemaVersion`
- `pendingSync`
- `title`
- `startDate`
- `endDate`
- `metricType`
- `goalValue`

## Field Conventions

- `id` should be stable and unique across devices
- `userId` scopes records to the owning account
- `createdAt` and `updatedAt` are needed for merge logic and auditability
- `deletedAt` enables tombstones for safe sync deletion
- `deviceId` helps identify the last writer and origin device
- `schemaVersion` allows future migrations
- `pendingSync` marks local changes waiting to be uploaded or reconciled

## Design Notes

- keep raw finance records separate from social surfaces
- store only the minimum data needed for sync
- avoid coupling the social model to the expense ledger more than necessary
- preserve local-first data as the source of truth until sync is enabled
