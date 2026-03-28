# SubWatch Closed Beta Pre-Rollout Checklist

## Packaging and identity

- Confirm package target is Google Play closed testing
- Confirm intended artifact is `build/app/outputs/bundle/release/app-release.aab`
- Confirm signing values are present locally
- Confirm `pubspec.yaml` version is `0.1.0+1`
- Confirm app label is `SubWatch`
- Confirm package identity is `app.subscriptionkiller`
- Confirm launcher icon is the intended final icon

## Build and install

- Build the signed release AAB
- Build the signed release APK for install sanity
- Confirm the artifact being shared matches the intended version name/code
- Install the sanity-check build on at least one Android device

## Fresh-install product sanity

- Fresh install opens cleanly
- First-run screen feels calm and trust-first
- Permission explanation is readable and honest
- Grant path works
- Browse-without-grant path works
- Denied path works
- Settings-return path works

## Product state sanity

- Zero-result path is sane
- Populated Home is sane
- Review is understandable
- Bundled/included services stay separate
- Manual add path still works
- Reminder manager and reminder detail path still work
- Settings trust/help paths still work

## Safety sanity

- Clear-all-data path requires deliberate confirmation
- Recovery rows do not dominate Settings
- Report-a-problem path opens the intended support channel
- Privacy policy link is final and valid

## Rollout readiness

- Tester invite message is final
- Feedback templates are final
- Severity definitions are agreed
- Trust-risk escalation owner is clear
- Batch 1 tester list is final
- Batch 2 expansion gates are agreed

## Hard blockers

- No final privacy policy URL
- Any blocker bug
- Any unresolved trust-risk issue
