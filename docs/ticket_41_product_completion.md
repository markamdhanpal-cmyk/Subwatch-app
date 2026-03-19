# Ticket 41: Product Completion Layer

## What was added
- A first-run and low-data guidance panel inside the dashboard shell.
- A trust and how-it-works sheet from the top app bar.
- Explicit next-step guidance for demo, denied, unavailable, review-first, and low-signal states.

## What stayed unchanged
- Subscription classification, resolver behavior, and ledger truth.
- Review thresholds and undo semantics.
- Refresh semantics, provenance rules, and storage boundaries.
- Android SMS runtime behavior and permission architecture.

## Guidance rules
- Demo state explains that the app starts with sample data and that device SMS is scanned only when the user asks.
- Denied and unavailable states explain the boundary honestly and do not imply background monitoring.
- Fresh low-data scans explain that a quiet result can be correct because weak or payment-like signals are not promoted.
- Review-first states point the user to Review Decisions without pressuring confirmation.

## Trust sheet summary
- Local-first by default.
- Refresh is explicit and device initiated.
- Uncertain items stay separate.
- Review actions and restored local state stay on this device.
