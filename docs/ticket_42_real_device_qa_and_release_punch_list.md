# Ticket 42: Real-device QA and Release Punch List

## QA strategy summary
This pass separated three layers of evidence:

1. Build readiness
- Confirm the Android app still builds cleanly.

2. Deterministic product-flow preflight
- Re-run the focused shell, provenance, review-action, and runtime-status widget suites that cover the release-critical trust surfaces.

3. Real-device execution check
- Attempt to enumerate attached Android hardware with `adb devices` before claiming an end-to-end device pass.

This report distinguishes between what was observed directly in tooling and what remains blocked until a real device is connected.

## Device and build context
- Date: 14 March 2026
- Workspace: `D:\Subscription killer`
- Flutter: 3.41.4 stable
- Dart: 3.11.1
- Android build checked: debug APK
- Real-device availability check: `adb devices`
- Result: no Android device attached at test time

`adb devices` output:

```text
List of devices attached
```

## Test scenarios executed

### A. Launch and framing
- App build health
  - Status: Passed
  - Evidence: `flutter build apk --debug`
  - Result: `build\app\outputs\flutter-apk\app-debug.apk` built successfully.
- First-run guidance surface
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_overview_test.dart -r expanded`
  - Result: demo state shows the guidance panel and trust-sheet entry.
- Trust sheet
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_overview_test.dart -r expanded`
  - Result: trust/how-it-works sheet opens and renders the expected sections.
- Real-device first impression
  - Status: Blocked
  - Reason: no hardware attached.

### B. SMS sync and permission flow
- Granted sync path
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_sync_test.dart -r expanded`
  - Result: refresh success message, fresh device snapshot copy, and post-sync layout render correctly.
- Denied path
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_sync_test.dart -r expanded`
  - Result: denied state remains honest and keeps safe local results visible.
- Unavailable path
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_sync_test.dart -r expanded`
  - Result: unavailable state remains explicit and disables sync affordance correctly.
- Real Android permission prompt behavior
  - Status: Blocked
  - Reason: no hardware attached.
- Real device SMS ingestion and refresh timing
  - Status: Blocked
  - Reason: no hardware attached.

### C. Data-state QA
- Demo/sample snapshot
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_overview_test.dart -r expanded`
- Quiet / low-signal post-sync state
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_sync_test.dart -r expanded`
- Restored snapshot / stale restored snapshot wording
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_provenance_test.dart -r expanded`
  - Result: restored snapshots remain visibly distinct from fresh device reads.
- Runtime source-status mapping
  - Status: Passed in widget/unit preflight
  - Evidence: `flutter test test\runtime_local_message_source_status_test.dart -r expanded`
- Real persisted relaunch flow on device
  - Status: Blocked
  - Reason: no hardware attached.

### D. Review and recovery
- Confirm action and undo
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_review_actions_test.dart -r expanded`
- Hide action and undo
  - Status: Passed in widget preflight
  - Evidence: `flutter test test\dashboard_shell_review_actions_test.dart -r expanded`
- Scroll to review lane
  - Status: Covered in widget preflight via guidance entry and review section rendering
  - Evidence: `flutter test test\dashboard_shell_overview_test.dart -r expanded`
- Real-device tap comfort and recovery discoverability
  - Status: Blocked
  - Reason: no hardware attached.

### E. Visual and interaction QA
- Narrow-width and wrapping sanity
  - Status: Partially passed
  - Evidence: current split shell suites remain green after Tickets 39-41 and no layout-specific test regressions were observed.
  - Remaining gap: actual handset readability and touch comfort are still unverified.
- Bottom-sheet readability and dismissal behavior
  - Status: Passed in widget preflight, blocked on device confirmation
- Snackbar and feedback clarity
  - Status: Passed in widget preflight
  - Evidence: sync and review-action suites remain green.

## Observed results
- SubWatch is build-stable and the release-critical shell flows remain green in deterministic tests.
- Trust surfaces are wired and behaving consistently in preflight:
  - first-run guidance
  - low-data guidance
  - trust/how-it-works sheet
  - fresh/restored/demo/unavailable wording
  - review confirm/hide/undo flows
- No concrete product regression was observed in the current preflight pass.
- The limiting factor is not app correctness discovered in code; it is the absence of connected Android hardware for final field execution.

## Trust and clarity findings
- Passed in preflight:
  - the app explains that demo data is only a starter view.
  - fresh vs restored vs unavailable states remain distinct.
  - review is clearly separated from confirmed subscriptions.
  - denied/unavailable states do not imply background monitoring.
- Not yet validated on hardware:
  - first-impression scanability on a real narrow device.
  - readability of the trust sheet and snapshot certificate in physical use.
  - whether the permission prompt plus post-denial recovery copy feels immediately clear in the real Android flow.

## Visual and interaction findings
- No concrete visual defect was reproduced in the current preflight pass.
- Remaining unverified areas are physical-device concerns only:
  - touch target comfort in action rows
  - chip readability at handset density
  - scroll discoverability for review decisions
  - bottom-sheet dismissal and visual weight on a real screen

## Runtime behavior findings
- Deterministic runtime behavior remains consistent in preflight:
  - sync success updates copy honestly
  - denied/unavailable states fail safely
  - restored provenance stays honest
  - review actions remain overlays with undo, not truth mutation
- Real-device runtime execution is still unverified because no device was connected.

## Release punch list

### Must fix before release
1. Real Android handset end-to-end pass
- Where: full product flow on at least one supported Android device
- Why it matters: release-critical flows still need actual hardware validation for permission prompts, SMS refresh behavior, physical readability, and trust perception.
- Severity/risk: High
- Recommended action: connect a real Android device and execute the Ticket 42 checklist end-to-end before external distribution.
- Type: QA / release process

2. Real persisted relaunch and restored-snapshot check on device
- Where: app relaunch after at least one successful SMS refresh
- Why it matters: restored-state honesty is a trust-critical claim and is only preflight-covered right now.
- Severity/risk: High
- Recommended action: refresh from device SMS, close/relaunch the app, and verify restored copy and freshness labels on hardware.
- Type: Behavior verification / trust QA

### Should fix if low risk
1. Add the completed real-device observations back into this report after handset execution
- Where: [ticket_42_real_device_qa_and_release_punch_list.md](./ticket_42_real_device_qa_and_release_punch_list.md)
- Why it matters: the release handoff should include actual hardware findings, not only preflight evidence.
- Severity/risk: Medium
- Recommended action: append concrete device model, Android version, and pass/fail notes once the handset run is completed.
- Type: Docs / release handoff

### Do not fix now
1. Parallel Flutter test runner instability in this sandbox
- Where: local QA environment when running multiple Flutter test processes at once
- Why it matters: it can waste QA time, but it is not a product bug and the split suites pass when run individually.
- Severity/risk: Low
- Recommended action: continue using the split suite approach from Ticket 31 for local verification.
- Type: Tooling / environment

## Overall release recommendation
Do not mark the app release-ready for external distribution yet.

Reason:
- build and deterministic preflight are healthy,
- no concrete app regression was found,
- but Ticket 42's acceptance criteria require a real Android device end-to-end pass, and that did not occur because no hardware was attached.

Current recommendation:
- `Conditional go after one real-device QA pass.`
- If the handset pass clears the permission, refresh, restored-state, review, and readability flows without new issues, the current punch list is small and the app looks close to release.

## Verification performed
- `adb devices`
- `flutter --version`
- `flutter analyze lib test`
- `flutter build apk --debug`
- `flutter test test\dashboard_shell_overview_test.dart -r expanded`
- `flutter test test\dashboard_shell_sync_test.dart -r expanded`
- `flutter test test\dashboard_shell_provenance_test.dart -r expanded`
- `flutter test test\dashboard_shell_review_actions_test.dart -r expanded`
- `flutter test test\runtime_local_message_source_status_test.dart -r expanded`

## Short title-style summary
`docs: record pre-release QA preflight and real-device blocker`

