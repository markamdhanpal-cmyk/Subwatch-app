import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/application/use_cases/project_review_queue_use_case.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/entities/subscription_event.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/projections/deterministic_dashboard_projection.dart';
import 'package:sub_killer/domain/resolvers/deterministic_resolver.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('Review Queue Projection', () {
    const projection = DeterministicDashboardProjection();
    const resolver = DeterministicResolver();
    final occurredAt = DateTime(2026, 3, 12, 22, 30);

    ServiceLedgerEntry entry({
      required String key,
      required ResolverState state,
      EvidenceTrail? evidenceTrail,
    }) {
      return ServiceLedgerEntry(
        serviceKey: ServiceKey(key),
        state: state,
        evidenceTrail: evidenceTrail ?? EvidenceTrail.empty(),
      );
    }

    SubscriptionEvent event({
      required String id,
      required String service,
      required SubscriptionEventType type,
    }) {
      return SubscriptionEvent(
        id: id,
        serviceKey: ServiceKey(service),
        type: type,
        occurredAt: occurredAt,
        sourceMessageId: 'msg-$id',
        evidenceTrail: EvidenceTrail(
          messageIds: <String>['msg-$id'],
          eventIds: <String>[id],
          notes: <String>[type.name],
        ),
      );
    }

    test(
        'unknownReview stays hidden from review until stronger evidence exists',
        () {
      final ledgerEntry = resolver.resolve(
        event: event(
          id: 'review-1',
          service: 'MYSTERY_SUB',
          type: SubscriptionEventType.unknownReview,
        ),
      );

      expect(ledgerEntry.state, ResolverState.possibleSubscription);

      final reviewItems =
          projection.buildReviewQueue(<ServiceLedgerEntry>[ledgerEntry]);
      expect(reviewItems, isEmpty);
    });

    test('pendingConversion becomes a review item', () {
      final reviewItems = projection.buildReviewQueue(<ServiceLedgerEntry>[
        entry(key: 'JIOHOTSTAR', state: ResolverState.pendingConversion),
      ]);

      expect(reviewItems, hasLength(1));
      expect(reviewItems.single.serviceKey.value, 'JIOHOTSTAR');
      expect(
        reviewItems.single.reasonLine,
        'A recurring setup was found, but billing is still missing',
      );
    });

    test('verificationOnly becomes a review item', () {
      final reviewItems = projection.buildReviewQueue(<ServiceLedgerEntry>[
        entry(key: 'CRUNCHYROLL', state: ResolverState.verificationOnly),
      ]);

      expect(reviewItems, hasLength(1));
      expect(reviewItems.single.serviceKey.value, 'CRUNCHYROLL');
      expect(
        reviewItems.single.detailsBullets,
        contains(
            'Tiny verification charges do not prove an active paid subscription.'),
      );
    });

    test('possibleSubscription is hidden from the review queue by default', () {
      final reviewItems = projection.buildReviewQueue(<ServiceLedgerEntry>[
        entry(
          key: 'MYSTERY_SUB',
          state: ResolverState.possibleSubscription,
          evidenceTrail: EvidenceTrail(
            notes: <String>[
              'v2:reason=weakRecurringSignalsObserved',
            ],
          ),
        ),
      ]);

      expect(reviewItems, isEmpty);
    });

    test('activePaid is excluded from the review queue', () {
      final reviewItems = projection.buildReviewQueue(<ServiceLedgerEntry>[
        entry(key: 'NETFLIX', state: ResolverState.activePaid),
      ]);

      expect(reviewItems, isEmpty);
    });

    test('activeBundled is excluded from the review queue', () {
      final reviewItems = projection.buildReviewQueue(<ServiceLedgerEntry>[
        entry(key: 'AIRTEL_BUNDLE', state: ResolverState.activeBundled),
      ]);

      expect(reviewItems, isEmpty);
    });

    test('ignored oneTimeOnly and cancelled are excluded from the review queue',
        () {
      final reviewItems = projection.buildReviewQueue(<ServiceLedgerEntry>[
        entry(key: 'IGNORED', state: ResolverState.ignored),
        entry(key: 'SHOPPING', state: ResolverState.oneTimeOnly),
        entry(key: 'OLD_SUB', state: ResolverState.cancelled),
      ]);

      expect(reviewItems, isEmpty);
    });

    test('unresolved possible subscriptions stay out of the review queue', () {
      final reviewItems = projection.buildReviewQueue(<ServiceLedgerEntry>[
        entry(key: 'UNRESOLVED', state: ResolverState.possibleSubscription),
      ]);

      expect(reviewItems, isEmpty);
    });

    test('multiple mixed ledger entries produce the correct review queue',
        () async {
      final repository = InMemoryLedgerRepository();
      await repository.write(
        entry(key: 'NETFLIX', state: ResolverState.activePaid),
      );
      await repository.write(
        entry(
          key: 'JIOHOTSTAR',
          state: ResolverState.pendingConversion,
          evidenceTrail: EvidenceTrail(
            notes: <String>['v2:reviewPriority=0.61'],
          ),
        ),
      );
      await repository.write(
        entry(
          key: 'CRUNCHYROLL',
          state: ResolverState.verificationOnly,
          evidenceTrail: EvidenceTrail(
            notes: <String>['v2:reviewPriority=0.84'],
          ),
        ),
      );
      await repository.write(
        entry(
          key: 'MYSTERY_SUB',
          state: ResolverState.possibleSubscription,
          evidenceTrail: EvidenceTrail(
            notes: <String>[
              'v2:reason=weakRecurringSignalsObserved',
              'v2:reviewPriority=0.28',
            ],
          ),
        ),
      );
      await repository.write(
        entry(key: 'SHOPPING', state: ResolverState.oneTimeOnly),
      );
      await repository.write(
        entry(key: 'AIRTEL_BUNDLE', state: ResolverState.activeBundled),
      );

      final reviewItems = await ProjectReviewQueueUseCase(
        ledgerRepository: repository,
        dashboardProjection: projection,
      ).execute();

      expect(reviewItems, hasLength(2));
      expect(
        reviewItems
            .map((item) => item.serviceKey.value)
            .toList(growable: false),
        <String>['CRUNCHYROLL', 'JIOHOTSTAR'],
      );
    });

    test(
        'possibleSubscription entries do not surface in review ranking by default',
        () {
      final reviewItems = projection.buildReviewQueue(<ServiceLedgerEntry>[
        entry(
          key: 'GOOGLE_PLAY',
          state: ResolverState.possibleSubscription,
          evidenceTrail: EvidenceTrail(
            notes: <String>[
              'v2:reason=paidEvidenceObserved',
              'v2:reason=likelyPaidNeedsMoreHistory',
              'v2:reviewPriority=0.67',
            ],
          ),
        ),
        entry(
          key: 'MYSTERY_SUB',
          state: ResolverState.possibleSubscription,
          evidenceTrail: EvidenceTrail(
            notes: <String>[
              'v2:reason=weakRecurringSignalsObserved',
              'v2:reviewPriority=0.18',
            ],
          ),
        ),
      ]);

      expect(reviewItems, isEmpty);
    });
  });
}
