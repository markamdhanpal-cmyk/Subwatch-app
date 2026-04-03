# Legacy Retirement Status (Phase 5)

## Live runtime truth path
- `ScanSubscriptionsV3UseCase`
- `ServiceKeyResolverV2`
- `SubscriptionDecisionEngineV3`
- Service-level aggregation and projection

## Retired in this finish pass
- `lib/application/use_cases/resolver_pipeline_use_case.dart`

## Compatibility-only artifacts (deferred)
- `lib/application/use_cases/event_pipeline_use_case.dart`
- `lib/domain/contracts/event_classifier.dart`
- `lib/domain/entities/parsed_signal.dart`
- `lib/domain/resolvers/deterministic_resolver.dart`

## Still live domain primitives (not yet retireable)
- `lib/domain/entities/subscription_event.dart`
- `lib/domain/enums/subscription_event_type.dart`

These are still used by the v3 runtime bridge (`scan_subscriptions_v3_use_case.dart` and decision/persistence wiring), so deleting them now would break live ingestion.

## Why not hard-delete all deferred compatibility files yet
- Some active tests still import `deterministic_resolver.dart` and `event_pipeline_use_case.dart` for regression assertions.
- Extractor helper wiring still routes lifecycle parsing through parsed-signal compatibility types.

## Removal path
1. Migrate remaining resolver/event-era tests to v3 evidence-first ingestion assertions.
2. Delete `deterministic_resolver.dart` once no tests import it.
3. Move lifecycle extractor helper outputs off `ParsedSignal`/`EventClassifier` and then retire those files.
4. Retire `event_pipeline_use_case.dart` once all compatibility regression tests are replaced.

## Guardrail
- Compatibility files are deprecated and must not be used as live runtime truth.
