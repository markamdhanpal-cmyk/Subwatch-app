# Ticket 32: release-readiness final polish

## Finalized for launch

- Empty dashboard states now explain what is missing instead of showing a generic `None`.
- Review undo copy now says items were returned to review, which matches the actual recovery behavior.
- Failure snackbars now explain that current local results were kept and that failed review actions did not mutate state.
- Demo, fresh device SMS, restored local snapshot, denied, and unavailable paths remain distinct in shell copy and provenance.

## Final sanity checklist

- Manual refresh remains explicit and application-driven.
- Restored local snapshots are still clearly labeled as restored, not fresh.
- Denied and unavailable SMS states fail safely without pretending a device read happened.
- Review confirm, dismiss, and undo flows remain reversible and visible.
- Empty confirmed/review/trial sections now stay understandable during first-run and fallback cases.
- No classifier, resolver, ledger, or projection rules were widened in this ticket.
