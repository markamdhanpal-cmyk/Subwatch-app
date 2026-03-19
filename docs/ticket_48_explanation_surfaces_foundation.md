# Ticket 48: Explanation Surfaces Foundation

## Scope
- Add contextual explanation entry points from snapshot, confirmed, review, and bundled/trial surfaces.
- Keep explanation copy derived from existing trusted state only.
- Reuse one generic explanation sheet instead of adding new navigation.

## Layer placement
- Domain: unchanged.
- Application: explanation presentation mapping only.
- Storage: unchanged.
- Platform/runtime: unchanged.
- Presentation: explanation buttons plus a shared bottom sheet.

## Notes
- Explanations do not change truth, counts, review outcomes, or refresh behavior.
- The copy stays short, local-first, and conservative.
- No raw SMS content is persisted or dumped into the UI.
