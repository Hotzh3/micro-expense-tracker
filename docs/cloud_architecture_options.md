# Cloud Architecture Options

This document compares future cloud approaches for Pocket Leak. It does not recommend implementing cloud now.

## A. Firebase + Google Sign-In

### Pros

- flexible schema and fast iteration
- good fit for social features and realtime collaboration
- easier to extend toward Android or web in the future
- Firestore realtime listeners can simplify sync-like experiences

### Cons

- privacy labeling and disclosure become more complex
- account, rule, and backend design work increases quickly
- cost can grow with reads, writes, and realtime usage
- finance data in a third-party backend requires careful retention and access policy design

## B. Sign in with Apple + CloudKit

### Pros

- Apple-native and familiar for iOS users
- strong privacy positioning for an iOS-first product
- CloudKit can fit a local-first, Apple-only roadmap well
- fewer cross-platform concerns if the product stays iOS-centric

### Cons

- less flexible for future non-Apple platforms
- social features and broad sharing can be harder to build
- identity and account experiences are tied more tightly to the Apple ecosystem

## C. Hybrid Firebase Auth with Apple + Google

### Pros

- flexible identity options
- can support Apple-friendly onboarding while keeping Google available
- useful if the product later needs cross-platform or broader social reach

### Cons

- more implementation work than a single-provider strategy
- more account edge cases and more maintenance
- identity complexity can grow before the core finance experience is ready

## Decision Notes

- if Pocket Leak remains iOS-only and privacy-first, CloudKit is usually the cleaner future fit
- if future growth depends on cross-platform social reach, Firebase becomes more attractive
- if the app ever needs both Apple-native privacy and broader account flexibility, a hybrid can work, but it should be justified by product scope rather than as a default choice

## Recommendation For Now

Do not implement any cloud architecture yet. Keep the current local-first model, finish portfolio polish, and revisit this decision only when Phase 8 becomes a real product requirement.
