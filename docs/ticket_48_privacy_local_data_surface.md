# Ticket 48: Privacy and Local Data Completion Surface

## Current roadmap phase
- Phase A - Completion

## Exact ticket
- Add a dedicated `Privacy & local data` explainer reachable from the dashboard controls sheet.

## Why this ticket comes next
- The app already has a trust sheet and a lightweight controls/about surface.
- The next missing completion layer is a dedicated privacy-first explainer that clarifies local storage boundaries and explicit SMS access.
- This improves trust and product completeness without inventing fake settings or adding new runtime behavior.

## Layer placement
- Domain: unchanged.
- Application: unchanged.
- Storage: unchanged.
- Platform: unchanged.
- Presentation: controls-sheet entry plus privacy/local-data bottom sheet.

## Scope kept intentionally small
- Added one new help/privacy surface.
- Reused existing sheet components and dashboard styling.
- No settings toggles, no feedback plumbing, no truth mutation.

## Risks intentionally avoided
- No fake preferences.
- No cloud/export/account framing.
- No payment or spend language.
- No claims that raw SMS is stored as app history.
