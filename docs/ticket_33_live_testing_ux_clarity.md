# Ticket 33: Live-Testing UX Clarity Hardening

## What changed
- Made the primary sync action explicitly about refreshing from device SMS.
- Shortened provenance headings so demo, fresh device, restored local, and safe fallback states read more plainly.
- Added a small application-level review item presentation model so review rows explain why a manual decision is needed without exposing classifier internals.
- Tightened confirm, dismiss, undo, and failure feedback so each message says whether visible state changed.
- Clarified the review-queue empty state as a decision queue rather than a background process.

## Boundary
- Domain rules, resolver outcomes, ledger truth, storage, and Android SMS behavior are unchanged.
- Copy mapping lives in application presentation models and the existing source-status model.
- The dashboard shell remains a thin renderer for those presentation values plus action dispatch.

## Live-testing friction addressed
- Demo state no longer looks like passive monitoring.
- Device refresh no longer reads like a broad inbox import.
- Restored and fallback provenance remains honest, but easier to scan.
- Review items now explain that confidence is limited and a user decision is required.
- Action feedback now explicitly says when state was kept versus changed.
