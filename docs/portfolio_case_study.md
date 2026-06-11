# Pocket Leak Portfolio Case Study

## Context

Pocket Leak started as a local-first iPhone micro-expense tracker focused on the kind of spending people forget: coffee, rides, snacks, convenience-store purchases, and recurring subscriptions.

## Problem

The hard part was not finance math. The hard part was capture friction. If logging an expense takes too long, users stop doing it.

## Product Decisions

- make Quick Add the primary action
- keep the app local-first and privacy-safe
- support pasted and shared text explicitly, not passively
- add Dashboard, History, Goals, and Insights so the data feels useful after capture
- build Demo Mode so the repo can be shown publicly without exposing real spending

## Technical Decisions

- SwiftUI for the main app
- local JSON persistence for portability and clarity
- cached derived summaries so large local datasets stay responsive
- shared formatters and helper services for consistency
- widget and share extension targets to show iOS platform depth

## Local-First Approach

The app keeps spending on device and does not require login, cloud sync, or remote services to work.

That choice shaped the rest of the product:

- the parser only runs on explicit user input
- widgets only read local summaries
- exports are generated locally
- demo data is synthetic and safe for screenshots

## Parser And Privacy

Pocket Leak does not scrape bank notifications. It only parses text the user pastes or explicitly shares. That keeps the flow explainable, reversible, and aligned with iOS privacy constraints.

## Widgets And Share Extension

The widget gives a glanceable summary without exposing private account data. The share extension demonstrates a realistic iOS integration point for explicit text handoff.

## Dashboard

Dashboard was designed to answer a simple question quickly: what is leaking money right now?

It combines totals, category distribution, trends, signals, goals, budgets, and upcoming recurring expenses into a single screen.

## Stress Testing

The repo includes stress testing plans and synthetic data scenarios so large local datasets can be validated before release. That matters because the app is meant to feel fast even after months of local expense history.

## Lessons Learned

- product quality depends on reducing capture friction
- local-first architecture can still feel rich and modern
- demo data is essential for a portfolio project
- cached summaries matter once lists and derived analytics grow
- platform constraints should shape the product story, not fight it

## Next Steps

- final screenshot set
- recorded demo video
- release notes and repo topics cleanup
- physical device QA
- optional paid distribution later through Apple Developer Program

