# Product Brief

## Context

Pocket Leak is a local-first iPhone app for tracking micro-expenses quickly and presenting the result as a polished portfolio project.

## Problem

Small daily purchases are easy to forget, especially when logging them takes too long. People do not need a heavyweight finance suite to understand coffee, transport, snacks, delivery, and recurring subscriptions. They need a fast capture flow and a clear local summary.

## Target User

- iPhone users who want a lightweight spending tracker
- People who prefer manual control over automatic bank import
- Portfolio reviewers looking for a realistic, well-structured native iOS app

## Product Goals

- Make expense capture feel fast enough to use daily
- Keep all personal data local
- Show useful summaries without forcing account creation
- Support screenshots, demos, and video recording with safe synthetic data

## Non-Goals

- No bank scraping
- No cloud sync
- No login or social features
- No payment processing
- No full accounting suite
- No platform-dependent bank notification reading

## Product Shape

- Quick Add for fast entry
- Dashboard for high-level spending signals
- History for browse and filters
- Goals for weekly and monthly limits
- Insights for trend and category analysis
- Widgets for glanceable status
- Share Extension and manual parser for explicit text handoff

## Technical Direction

- SwiftUI-first architecture
- Local JSON persistence
- Cached summaries for large local datasets
- Explicit parsing only when the user pastes or shares text
- Demo Mode for safe portfolio captures

## Portfolio Angle

Pocket Leak is strongest as a portfolio artifact because it combines:

- product thinking around capture friction
- native iOS architecture
- privacy-aware design choices
- local data handling
- widgets and share extension integration
- performance cleanup for large lists and derived summaries

