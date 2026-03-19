# Ticket 47: Completion Audit and Controls Surface

## Completion audit

### Must-have completion surfaces
- A lightweight controls/help surface that gives the app a clear place for real user-facing controls.
- A plain-language local-first/privacy summary that explains what stays on device.
- A simple about surface that explains what SubWatch is and what it is not.

### Good-to-have polish
- Real version/build information once a release metadata source is wired.
- A report-issue or feedback entry once there is a real destination to open.
- Additional release help text after a real-device QA pass confirms remaining confusion.

### Out-of-scope risky expansion
- Fake settings toggles that do not map to real behavior.
- Account, cloud, export, or notification flows.
- Any control that changes classifier, resolver, review, or persistence truth.
- Payments, spend, or budgeting surfaces.

## Chosen safe ticket
- Add a `Controls & About` sheet from the dashboard app bar.
- Keep it presentation-only and deterministic.
- Expose only real actions:
  - jump to Review Decisions
  - open How SubWatch works
- Explain the local-first model and the product boundary in one place.

## Layer placement
- Domain: unchanged.
- Application: unchanged.
- Storage: unchanged.
- Platform: unchanged.
- Presentation: app-bar entry plus controls/about bottom sheet.

## Why this was the safest next step
- It makes the app feel more complete without inventing fake settings.
- It strengthens trust by clarifying local-only behavior and explicit refresh.
- It adds user control surfaces without widening business logic.
