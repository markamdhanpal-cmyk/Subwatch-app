# SubWatch Closed Beta Rollout Pack

## Package target

- Recommended distribution target: Google Play closed testing
- Recommended artifact: signed release Android App Bundle
- Target output path: `build/app/outputs/bundle/release/app-release.aab`
- Local install sanity artifact: `build/app/outputs/apk/release/app-release.apk`
- App label sanity: `SubWatch`
- Package identity sanity: `app.subscriptionkiller`
- Launcher asset sanity: Android launcher assets are present under `android/app/src/main/res/mipmap-*`

## Versioning status

- Current app version from `pubspec.yaml`: `0.1.0+1`
- Intended Android version name: `0.1.0`
- Intended Android version code: `1`
- Recommendation: do not invite testers on any build with a different version name/code pair than `0.1.0+1`

## Release signing status

- Release signing source: `android/key.properties` or `SUB_KILLER_UPLOAD_*` environment variables
- Current workspace status: configured locally through ignored files
- Local keystore path: `android/subwatch-upload-keystore.jks`
- Local key properties path: `android/key.properties`
- Result: signed release APK and signed release AAB were produced from this machine
- Blocking impact: no signing blocker remains for this workspace

## Privacy policy status

- Current status: final policy content now exists locally in `docs/privacy_policy.md`, but no final public privacy policy URL is live yet
- Beta impact: Google Play distribution should be treated as blocked until a final public URL exists
- Interim wording status: tester and metadata copy can say the app is private and on-device, and the policy content is ready to publish, but distribution metadata still needs the actual URL

## Distribution metadata draft

### Short summary

Private subscription tracker for Indian SMS, with careful on-device review.

### Long description

SubWatch helps you spot real paid subscriptions in noisy device SMS histories.

It is built to be conservative:
- a payment is not automatically treated as a subscription
- setup and mandate messages are not treated as active paid plans
- Re 1 and Rs 2 verification charges are not treated as active subscriptions
- uncertain recurring-looking cases stay in Review instead of being over-confirmed
- included telecom or bundled access stays separate from paid subscriptions

SubWatch is also private by design:
- your messages are checked on this phone
- no cloud account is needed
- the app is focused on subscriptions, not general expense tracking

What you can do in this beta:
- scan your messages on demand
- review what SubWatch found
- confirm paid subscriptions
- keep bundled access separate
- add a subscription yourself if something was missed
- manage reminders and recovery controls from Settings

This is a limited closed beta. Some uncertain SMS cases may still need your review. That is intentional. Your feedback is most useful when something feels confusing, is classified incorrectly, or makes the app feel less trustworthy.

### Trust/privacy positioning line

Private on this phone. Your messages are checked on-device.

### Tester-facing explanation

SubWatch is a careful Android utility that looks for real paid subscriptions in device SMS and keeps uncertain cases in Review instead of guessing.

### Beta disclaimer

Closed beta. Some uncertain cases may still need your review. The app is intentionally conservative, and your feedback helps improve clarity and correctness.

### Support and feedback path

- In-app path: `Settings > Report a problem`
- Email target already wired in app: `support@subwatch.app`
- Recommended beta subject prefix format:
  - `[BLOCKER]`
  - `[TRUST]`
  - `[ONBOARDING]`
  - `[REMINDER]`
  - `[UX]`
  - `[BUG]`

### Category and positioning draft

- Play category draft: `Productivity`
- Positioning draft: private subscription tracker, not a finance dashboard

## Tester starter pack

### Who this beta is for

- Android users in India with real, messy SMS histories
- People who actively pay for OTT, utilities, memberships, or recurring digital services
- Testers who can describe confusing cases clearly
- A small number of careful UX note-takers and edge-case users

### Who is less useful for round 1

- People with very little SMS history
- People using unsupported platforms
- Anyone looking for a full expense tracker or budget app
- Very large casual tester groups with low reporting discipline

### What to do first after install

1. Open the app from a clean install.
2. Read the first-run permission explanation.
3. Decide whether the permission flow feels comfortable and clear.
4. Run your first scan.
5. Check whether confirmed subscriptions, Review items, and included services feel sensible.
6. Visit Settings and check reminders, privacy/help, and recovery controls.

### High-value feedback

- Wrong subscription confirmations
- Clear false positives
- Clear false negatives where a paid recurring service was missed
- Bundled or included services shown as paid subscriptions
- Confusing Review cases
- Permission discomfort or trust concerns
- Reminder or Settings flows that feel unsafe or unfinished
- Anything that makes the app feel less private, less clear, or less trustworthy

### Lower-priority feedback

- Minor icon or spacing preferences with no usability impact
- Personal feature requests outside the current beta scope
- General "make it prettier" feedback without a concrete problem

## Round 1 rollout recommendation

### Batch size

- Recommended round 1 size: 12 to 18 testers

### Tester mix

- 5 to 7 everyday Android users with active Indian SMS histories
- 3 to 4 users with especially messy SMS inboxes or multiple recurring services
- 2 to 3 careful UX feedback givers
- 1 to 2 edge-case or power users, such as dual-SIM or unusually high-notification users

### Why this mix

- It maximizes signal on trust, clarity, and real SMS messiness
- It keeps triage volume manageable
- It reduces the chance of widening rollout before false-positive risk is understood

### Exclude from round 1

- Broad friend-and-family blast lists
- Users expecting banking, expense, or budgeting features
- People unlikely to submit structured feedback

### Batch 2 expansion gates

- No unresolved blocker issues
- No unresolved trust-risk issue
- No repeated false-positive pattern across the same service category
- First-run and permission feedback is mostly clear
- Review is understandable for most testers
- Reminder and Settings flows do not produce repeated trust complaints

## Feedback workflow

### Primary channel

- Primary intake: `support@subwatch.app`
- Preferred entry point: in-app `Report a problem`
- Team-side workflow: copy every report into the shared beta tracker using the required fields below

### Required report fields

- Subject line with severity/tag prefix
- Build version
- Device model
- Android version
- What the tester expected
- What happened instead
- Whether this affects trust, classification, onboarding, reminder, or settings behavior
- Screenshot or screen recording if relevant
- SMS case details with sensitive data redacted where possible

### Severity definitions

- Blocker: app cannot be installed, launched, scanned, or trusted for normal beta use
- High: wrong subscription classification, major permission/review/reminder failure, or serious trust confusion
- Medium: workflow friction, misleading copy, non-blocking layout issue, or recoverable bug
- Low: cosmetic issue, minor wording preference, or polish-only inconsistency

### Trust-risk escalation

- Any report involving privacy, unexpected message handling, unsafe destructive behavior, or misleading subscription certainty is tagged `trust-risk`
- `trust-risk` reports are reviewed before normal UX or cosmetic issues
- Any unresolved `trust-risk` item pauses new tester invites

### Duplicate handling

- First valid report becomes the canonical issue
- Later matching reports are linked as duplicates
- Duplicate count is still tracked because repeated confusion matters

### Required issue tags

- `false-positive`
- `false-negative`
- `review-confusion`
- `onboarding`
- `permission`
- `reminder`
- `settings`
- `destructive-action`
- `trust-risk`
- `copy`
- `layout`

## Rollout gates

### Must be true before invites go out

- Signed release artifact exists for the intended distribution path
- Version name/code is confirmed
- App identity is correct
- Fresh-install first-run path is sane
- Permission path is sane
- Home, Review, Settings, and reminders are sanity-checked
- Feedback instructions and templates are ready
- Privacy policy URL is final and ready for distribution metadata

### Issues that block rollout

- No final privacy policy URL
- Any blocker bug
- Any unresolved trust-risk issue
- Repeated false-positive pattern in a core paid service area
- Broken onboarding, permission, reminder, or destructive-action flow

### Issues acceptable during closed beta

- Minor copy polish
- Small visual inconsistencies
- Non-blocking layout edge cases with a workaround
- Narrow low-priority feature requests outside scope

### Pause or stop-beta conditions

- Multiple testers report the same trust-risk issue
- A real false-positive cluster appears for a major service
- Permission or first-run discomfort is common enough to reduce trust
- Reminder or destructive controls behave unsafely

### Round 1 signals that matter

- Number of blocker issues
- Number of trust-risk issues
- Number of false-positive reports
- Number of false-negative reports
- Whether Review is understood
- Whether first-run permission framing feels comfortable
- Whether Settings and reminders feel trustworthy
