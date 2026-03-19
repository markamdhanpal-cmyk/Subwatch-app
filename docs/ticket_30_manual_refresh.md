# Ticket 30: Manual refresh and ingestion hardening

## What manual refresh does

- Manual refresh is explicit and application-driven. It only happens when the user presses the SMS sync action.
- A successful refresh re-reads the currently selected local SMS source, clears the in-memory ledger, recomputes events and ledger state from scratch, and then replaces the persisted runtime snapshot with the new deterministic result.
- Provenance stays honest: a real device read is shown as a fresh device SMS snapshot with a new last-refreshed timestamp.

## What manual refresh does when device SMS cannot be read

- If SMS access is denied or unavailable, refresh does not pretend a fresh device read happened.
- If a persisted snapshot already exists, the app keeps that last persisted snapshot visible instead of overwriting it with an empty fallback result.
- If no persisted snapshot exists yet, the app can still project the safe local fallback state, but that is shown as fallback state rather than device SMS.

## What refresh does not do

- It does not append onto previous derived runtime state.
- It does not run as background sync, listener-based ingestion, or cloud sync.
- It does not change classifier, resolver, ledger truth, dashboard projection, or review queue rules.
- It does not claim that restored local state is the same as a fresh device read.

## Hardening rules

- Restore mode only trusts a persisted snapshot record if it can actually be parsed.
- Malformed persisted state falls through to a clean recompute from the current source instead of surfacing an empty restored snapshot.
- Failed manual refresh attempts preserve the last trusted persisted snapshot and its original last-refreshed timestamp.
- Repeated successful refreshes remain deterministic because each run starts from a cleared ledger and replaces persisted derived state.
