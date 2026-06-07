# Product Brief

## Problem Statement

People regularly spend on tiny items such as coffee, snacks, transport, tips, and delivery fees. These expenses are small in isolation but meaningful over a week or month. The problem is not motivation alone; it is capture friction. If recording an expense takes too long, it will not happen.

## Target User

- iPhone users who want better awareness of small daily spending
- People who prefer fast, manual logging instead of complex budgeting apps
- Users who want a lightweight companion for habit tracking rather than a full finance suite

## MVP Scope

- Quick add flow with amount and category
- Optional merchant and note fields
- Simple dashboard with placeholder summary blocks
- History list structure
- Insights skeleton with placeholder metrics
- Minimal black-and-white visual identity

## Non-Goals

- Full accounting or budgeting workflows
- Bank account linking
- Reading third-party bank notifications
- OCR-based extraction
- Shared cloud sync
- Payment execution or financial transactions

## Technical Limitations

The app should not be designed around directly reading push notifications from banking or payment apps. iOS does not provide general access to other apps' notifications, and relying on that would be fragile and platform-dependent. The MVP should instead support a quick manual capture flow, with later optional entry points such as Shortcuts/App Intents or user-pasted text.

## Architecture Overview

- SwiftUI for the app interface
- In-memory sample data for the foundation phase
- A view model layer for state and actions
- A lightweight service layer placeholder for future storage and import logic
- Theme primitives for reusable design components

## Default Categories

- Coffee
- Food
- Transport
- Snacks
- Going Out
- Delivery
- Small Purchases
- Tips
- Other

## Privacy Approach

- Keep the MVP local-first
- Avoid bank account access in the base product
- Make any future import or parsing flows opt-in
- Minimize sensitive data collection

## Future Ideas

- SwiftData persistence
- App Intents and Shortcuts integration
- Back Tap quick capture
- Swift Charts insights
- Optional pasted text parsing
- OCR from receipts if useful and reliable

## LinkedIn and Portfolio Angle

Pocket Leak is best positioned as a focused product design and native iOS systems project. It demonstrates how to take a vague spending problem, narrow it into a frictionless capture workflow, and build an elegant mobile foundation that respects platform constraints.
