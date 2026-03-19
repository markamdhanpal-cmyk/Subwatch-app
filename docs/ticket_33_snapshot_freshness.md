# Ticket 33: runtime snapshot freshness and stale-state clarity

## Boundary placement

- Snapshot freshness stays in the application-facing source-status model.
- Freshness is derived from existing provenance timestamps and is not used to infer subscription truth.
- The dashboard shell only renders the mapped label and description.

## Freshness rules

- Fresh device SMS snapshot: shown as recently refreshed.
- Restored snapshot with refresh within 24 hours: shown as recent.
- Restored snapshot with refresh between 24 and 72 hours: shown as refresh suggested.
- Restored snapshot with refresh older than 72 hours: shown as potentially stale.
- Restored snapshot without refresh metadata: shown as freshness unknown.

## Safeguards

- No background refresh was added.
- No auto-refresh was added.
- No classifier, resolver, ledger, or projection behavior changed.
- No raw SMS content was newly persisted.
