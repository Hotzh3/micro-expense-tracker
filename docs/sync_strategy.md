# Sync Strategy

This document describes a future sync model for Pocket Leak. It does not change the current local-first implementation.

## Local-First Baseline

- the local store remains the source of truth on the device
- the app must work fully offline
- sync is additive, not required for basic use
- local capture must never wait on a network round trip

## Pending Sync

- every writable record can track whether it has pending sync work
- new records are created locally first
- updates mark the record dirty until upload succeeds
- deletes create tombstones so the deletion can be reconciled across devices

## Offline Support

- all core flows must continue to work without network access
- sync should resume automatically when connectivity returns
- failed uploads should not block local data entry

## Initial Conflict Strategy

- use last write wins initially
- store timestamps and device identity to support reconciliation
- keep merge rules simple until there is real-world conflict data

## Duplicate Prevention

- each record should have a stable unique identifier
- imported or synced data must be deduplicated by identity and origin metadata
- manual imports and sync uploads should not create duplicate expenses when the same event appears twice

## Delete Handling

- use tombstones rather than hard deletes for synced records
- preserve delete intent across devices
- allow local cleanup later when sync confirms the deletion

## Merge After Login

- if the product ever supports login after a local-only period, the app should merge existing local data into the authenticated account carefully
- the merge should be explicit and user-confirmed
- users should choose between keeping local data, replacing remote data, or merging both sets

## Logout Behavior

- logout should not silently destroy local records
- the app should define whether it keeps an offline local profile after account sign-out
- any remote association should be removable without harming the local archive

## Recommendation

Start with a local-first sync queue, a clear tombstone model, and a conservative merge policy. Do not introduce advanced collaboration rules until the single-user sync path is proven stable.
