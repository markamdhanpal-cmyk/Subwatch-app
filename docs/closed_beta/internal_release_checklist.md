# SubWatch — Pre-Beta Truth & Evidence Checklist

This checklist focuses on the **technical truth** of the subscription detection pipeline. Before rollout, every core signal class must prove it is deterministic and false-positive-averse.

## 1. Detector Truth & Precision

### Sender-ID Resolution (DLT)
- [x] **Prefix Matching**: Verify DLT prefixes (e.g., `SWIGGY`, `ZOMATO`, `G-ONE`) resolve to the correct High-Value merchant.
- [x] **Address Priority**: Confirm sender-prefix matching happens before fuzzy body-text matching.

### Mandate Lifecycle Logic
- [x] **Setup Separation**: Verify "Mandate Created/Setup" messages stay in the **Review Queue** or are correctly distinguished from active billing.
- [x] **Cancellation Awareness**: Verify "Mandate Cancelled" messages are **NOT** swallowed as noise and surface as evidence for Review.
- [x] **Netflix Exception**: Confirm Netflix mandate cancellation is successfully detected as subscription evidence.

### Telecom Bundle & Direct Billing
- [x] **Veto Escape**: Verify messages containing billing language ("Rs 499", "renewed") escape the generic "telecom bundle" veto even if "Airtel" or "Jio" is present.
- [x] **Bundle Separation**: Confirm regular recharges are suppressed or correctly categorized as "Included Benefits".

### Structural Noise & Vetoes
- [x] **RCS Metadata**: Confirm Google RCS bot signals (`.rcs.google.com`) are filtered early.
- [x] **Empty Message Hygiene**: Confirm zero-length bodies are dropped before classification.
- [x] **BNPL & Loan Noise**: Verify "Loan Suspended" or card-expiry noise is **NOT** classified as subscription evidence.

## 2. Ingestion & Persistence Trust

### Write Durability (Anti-Corruption)
- [x] **Atomic Writes**: Confirm `JsonFile*Store` uses temp-file-then-rename pattern for all writes.
- [x] **Startup Recovery**: Verify that partial/corrupt JSON files do not blank the ledger at startup.
- [x] **Review Persistence**: Confirm that user-dismissed/confirmed review actions are immediately durable.

### Ingestion Horizon
- [x] **Scanning Window**: Confirm 18-month default horizon is respected.
- [x] **Provenance Trace**: Verify that scanned results correctly record `DecisionExecutionMode.bridgeToLedger` (Live mode).

## 3. Product & Packaging Sanity

- [x] **Package Identity**: `app.subscriptionkiller` (SubWatch) confirmed.
- [x] **Version**: `0.1.0+1` confirmed.
- [x] **Privacy Policy URL**: [BLOCKER] No live public URL exists yet.
- [x] **Clear All Data**: Confirmation dialog is technically functional and clears the actual ledger/evidence files.

## 4. Final Beta Verdict

- **Detector Status**: **GREEN** (All core regressions passing fixture pack).
- **Execution Mode**: **LIVE** (`bridgeToLedger`).
- **Rollout Status**: **BLOCKED** by Privacy Policy URL.
