# SubWatch Closed Beta Templates

## Tester starter note

SubWatch is for Android users who want a careful view of real paid subscriptions from SMS, not a general payments or expense app.

Please focus on:
- whether the first-run and permission flow feels trustworthy
- whether confirmed subscriptions make sense
- whether bundled or included services stay separate
- whether Review feels understandable
- whether reminders and Settings feel safe and clear

Please spend less time on:
- cosmetic preferences without a usability issue
- feature ideas outside the current beta scope

When reporting a bug, include:
- your phone model
- Android version
- app version
- what you expected
- what happened instead
- screenshots or a short screen recording if useful

## General bug report template

Subject:
`[BUG][severity] short summary`

Body:

`Build version:`

`Phone model:`

`Android version:`

`Where it happened:`

`What I expected:`

`What happened instead:`

`Can I reproduce it again?`

`Screenshots/video attached: yes/no`

## Trust or classification issue template

Subject:
`[TRUST][severity] wrong subscription or confusing classification`

Body:

`Build version:`

`Phone model:`

`Android version:`

`Service or sender name:`

`Was this shown as Confirmed, Review, or Included with your plan?`

`What do you think it should have been?`

`Why:`

`Was this a false positive or false negative?`

`Redacted SMS text or screenshot:`

`Did this reduce your trust in the app? yes/no`

## Onboarding or permission issue template

Subject:
`[ONBOARDING][severity] first-run or permission issue`

Body:

`Build version:`

`Phone model:`

`Android version:`

`Where in the flow did this happen?`

`What screen or message felt unclear?`

`What did you expect to happen next?`

`What actually happened?`

`Screenshot/video attached: yes/no`

## Reminder or notification issue template

Subject:
`[REMINDER][severity] reminder or notification problem`

Body:

`Build version:`

`Phone model:`

`Android version:`

`Service name:`

`Reminder action taken:`

`What I expected:`

`What happened instead:`

`Was this about setup, edit, delete, or timing?`

`Screenshot/video attached: yes/no`

## UX confusion report template

Subject:
`[UX][severity] confusing moment`

Body:

`Build version:`

`Phone model:`

`Android version:`

`Which screen or flow felt confusing?`

`What did you think the app meant?`

`What would have made it clearer?`

`Screenshot/video attached: yes/no`

## Tester invite message

Hello, and thanks for joining the SubWatch closed beta.

SubWatch is a private Android app that checks your SMS on this phone to help you spot real paid subscriptions. It is intentionally conservative: uncertain cases stay in Review instead of being over-confirmed, and bundled or included access stays separate from paid subscriptions.

What to do first:
1. Install the beta build.
2. Open the app from a clean start.
3. Go through the first-run permission flow.
4. Run your first scan.
5. Check whether the results, Review items, and included services feel sensible.
6. Visit Settings and look at reminders, privacy/help, and recovery controls.

What feedback helps most:
- wrong subscription detection
- bundled services shown as paid
- confusing Review cases
- trust or privacy discomfort
- reminder, Settings, or permission issues
- bugs with a screenshot or short screen recording

Please send feedback to `support@subwatch.app`. If possible, use one subject prefix:
`[BLOCKER]`, `[TRUST]`, `[ONBOARDING]`, `[REMINDER]`, `[UX]`, or `[BUG]`

This is a limited beta. Some uncertain cases may still need your review. That is expected, and your feedback is especially useful when an SMS case feels confusing or incorrectly handled.
