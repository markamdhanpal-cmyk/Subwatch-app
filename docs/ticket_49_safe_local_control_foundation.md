# Ticket 49: Safe Local Control Foundation

## Scope
- Add reversible local overlays for ignore and hide.
- Keep ignore and hide separate:
  - Ignore suppresses local relevance/presentation.
  - Hide suppresses local visibility.
- Add one dashboard recovery surface for ignored and hidden items.

## Layer placement
- Domain: unchanged.
- Application: local control overlay models, store, orchestration, and application of overlays.
- Storage: local overlay persistence only.
- Platform/runtime: unchanged.
- Presentation: card/review actions plus one recovery section.

## Notes
- These controls do not change classifier, resolver, ledger, or review truth.
- They are local to this device and reversible.
- No bulk actions, rename, pin, or search were added in this ticket.
