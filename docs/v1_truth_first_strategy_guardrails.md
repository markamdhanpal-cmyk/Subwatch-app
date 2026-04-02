# SubWatch v1 Truth-First Guardrails

## Positioning
SubWatch is a privacy-first Android app for Indian users that surfaces high-confidence recurring charges and included mobile-plan benefits from on-device SMS.

Core line:
`SubWatch shows high-confidence recurring charges and included mobile-plan services from on-device SMS, with clear uncertainty when evidence is incomplete.`

## v1 Target Segment
- Indian Android users, age 22-35
- Salaried or early-career professionals in tier 1/2 cities
- Jio/Airtel-heavy SMS inboxes
- UPI-heavy but not UPI-only payment behavior
- Typically 5-15 recurring services (paid + included)

Primary user job:
`Show me my real recurring burn without making me do forensic cleanup.`

## Deliberate Tradeoffs
- Prefer precision over recall for surfaced paid items.
- Keep SMS-only scope explicit; do not pretend universal coverage.
- Keep annual recovery conservative; do not auto-confirm weak store-like clues.
- Keep possible/uncertain evidence separate from confirmed paid.
- Keep deterministic, explainable rules over opaque scoring complexity.

## Accuracy Promise (External)
- Confirmed list is high-confidence, not complete.
- Included services are shown separately from direct paid.
- Possible items are explicitly marked and excluded from confirmed totals.

Never claim:
- "We found all your subscriptions."
- "100% automatic subscription detection."
- "Complete coverage across all billing channels."

## Explicit v1 Non-Goals
- Family/shared-account financial modeling
- iPhone-first coverage
- Email parsing or bank scraping integrations
- "Magic" auto-confirmation behavior from weak evidence
- Fake ML complexity that reduces explainability

## Product Copy Rules
- Prefer labels: `Confirmed`, `Included with your plan`, `Possible`, `Ended`
- Never label paid without billed evidence.
- Never mix possible items into confirmed surfaces or spend totals.
