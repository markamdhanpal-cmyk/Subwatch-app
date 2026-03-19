# Ticket 31: dashboard shell test split

## What changed

- The old monolithic `dashboard_shell_test.dart` suite was split by concern into:
  - overview rendering
  - review action flows
  - provenance rendering
  - SMS sync states
- Shared widget test helpers now live in `test/support/dashboard_shell_test_harness.dart`.

## Why the old file timed out

- The original suite combined many widget tests that repeatedly used `pumpAndSettle()` after scrolls, loads, and snackbar-triggering actions.
- Those broad settles wait for transient UI work that is not relevant to the assertions, which makes the full file much slower than the focused cases.
- Individual tests were healthy; the suite organization and harness behavior were the unstable part.

## Harness hardening

- Initial shell loads now use a small deterministic pump sequence instead of broad settling.
- Tap-driven assertions use a short UI pump that is long enough for async state changes and snackbar entry, but does not wait for snackbar timeout.
- Shared fake gateways, capability providers, and temp snapshot store helpers reduce duplicated setup and keep each file focused.

## How to run

- `flutter test test/dashboard_shell_overview_test.dart`
- `flutter test test/dashboard_shell_review_actions_test.dart`
- `flutter test test/dashboard_shell_provenance_test.dart`
- `flutter test test/dashboard_shell_sync_test.dart`
