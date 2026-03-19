# Ticket 50: Local Label & Pin Foundation

## Scope
- Local label is a display-only rename on this device.
- Pin is presentation priority only within the current dashboard section.
- Both controls are local overlays and are fully reversible.

## Layer placement
- Domain: unchanged.
- Application: local presentation overlay models, store contract, persistence, and orchestration.
- Storage: local overlay state only.
- Presentation: organize sheet, rename/reset controls, pin/unpin controls, and pinned-first rendering.

## Guardrails
- No classifier, resolver, ledger, review-threshold, or service-identity mutation.
- No search, sort, filter, categories, tags, or bulk actions in this ticket.
- Local labels never become canonical service identity.
- Pinning does not change subscription truth or review behavior.
