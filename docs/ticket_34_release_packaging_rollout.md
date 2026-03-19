# Ticket 34: release packaging and rollout checklist polish

## Release summary

SubWatch v1 is a local-first Android app that scans device SMS only when the user explicitly asks it to. It confirms only high-confidence paid subscriptions, routes weaker recurring-looking signals into review, and keeps restored local snapshots visibly distinct from fresh device SMS reads.

## v1 in scope

- Explicit device SMS refresh from the dashboard
- Deterministic classification, resolution, ledger, and dashboard projection
- Local persisted derived snapshot restore
- Review queue confirm, hide, and undo flows
- Provenance and freshness wording for demo, fresh, restored, denied, unavailable, and fallback states

## Intentionally out of scope

- Background SMS monitoring or passive inbox scanning
- Cloud sync, accounts, analytics, or telemetry
- Payments dashboard behavior
- Automatic confirmation of weak recurring-looking messages
- Widened classifier, resolver, ledger, or review-queue rules

## Packaging checklist

- Verify `flutter analyze lib test`
- Verify focused runtime and shell coverage:
  - `flutter test test\\load_runtime_dashboard_persistence_test.dart -r expanded`
  - `flutter test test\\runtime_local_message_source_status_test.dart -r expanded`
  - `flutter test test\\dashboard_shell_overview_test.dart -r expanded`
  - `flutter test test\\dashboard_shell_review_actions_test.dart -r expanded`
  - `flutter test test\\dashboard_shell_provenance_test.dart -r expanded`
  - `flutter test test\\dashboard_shell_sync_test.dart -r expanded`
- Verify a packaging build with `flutter build apk --debug`
- Verify release signing is configured through `android/key.properties` or `SUB_KILLER_UPLOAD_*` environment variables
- Release APK: `flutter build apk --release`
- Release App Bundle: `flutter build appbundle --release`

## Manual rollout sanity checks

- First launch shows demo data clearly and does not imply background monitoring
- `Scan Device SMS` or `Refresh from Device SMS` stays explicit about reading from this device
- Granting SMS access produces a fresh device snapshot with honest provenance
- Denied and unavailable states keep safe copy and do not pretend a device read happened
- Restart after a successful refresh shows a restored local snapshot, not a fresh device read
- Review queue items explain that confidence is limited and a user decision is required
- Confirm, hide, and undo actions clearly show whether visible state changed

## Handoff notes

- Tickets 21 through 34 keep the rebuilt architecture local-first, deterministic, and trust-first.
- The shipped app is a subscription manager, not a payments inbox.
- Raw SMS remains device-local and is not persisted beyond the existing Android SMS read boundary.
- External Android release now expects:
  - package identity `app.subscriptionkiller`
  - a real local keystore
  - local-only signing values outside source control

