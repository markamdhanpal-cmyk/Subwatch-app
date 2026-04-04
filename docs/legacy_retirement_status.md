# Legacy Retirement Status (Phase 6 compatibility-exit cleanup)

## Live runtime truth path (unchanged)
- `ScanSubscriptionsV3UseCase`
- `ServiceKeyResolverV2`
- `SubscriptionDecisionEngineV3`
- Service-level aggregation and projection

## Retired in this cleanup pass
- `lib/application/use_cases/event_pipeline_use_case.dart`
- `lib/domain/contracts/event_classifier.dart`
- `lib/domain/resolvers/deterministic_resolver.dart`
- `lib/domain/contracts/service_identity_resolver.dart`
- `lib/domain/resolvers/deterministic_service_identity_resolver.dart`
- `test/event_pipeline_use_case_test.dart`
- `test/deterministic_resolver_test.dart`
- `test/deterministic_service_identity_resolver_test.dart`

## Deferred compatibility artifact (still present)
- `lib/domain/entities/parsed_signal.dart`

### Why deferred
- Legacy classifiers still emit `ParsedSignal` and are still used by evidence extractors.
- This pass reduced extractor coupling by removing explicit `ParsedSignal`-typed helper signatures, but classifier return types are still `ParsedSignal`.

### Next prerequisite for retirement
- Move classifier outputs to direct evidence payloads (or equivalent non-`ParsedSignal` carrier), then remove `parsed_signal.dart`.

## Still live domain primitives (not retireable in this pass)
- `lib/domain/entities/subscription_event.dart`
- `lib/domain/enums/subscription_event_type.dart`

These remain part of live v3 bridge semantics (`scan_subscriptions_v3_use_case.dart`, decision bridge mapping, and persistence wiring).

## Guardrails (must remain true)
- Compatibility files must not become runtime truth paths.
- Setup/micro/bundle/weak signals must not inflate to paid truth.
- Unresolved-first conservatism remains mandatory.

