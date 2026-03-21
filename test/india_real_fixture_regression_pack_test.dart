import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/projections/deterministic_dashboard_projection.dart';

import 'fixtures/india_real_sms_regression_fixture_pack.dart';

void main() {
  group('India real SMS regression fixture pack', () {
    late InMemoryLedgerRepository ledgerRepository;
    late LocalIngestionFlowUseCase ingestionUseCase;
    const projection = DeterministicDashboardProjection();
    final receivedAt = DateTime(2026, 3, 13, 9, 0);

    setUp(() {
      ledgerRepository = InMemoryLedgerRepository();
      ingestionUseCase = LocalIngestionFlowUseCase(
        ledgerRepository: ledgerRepository,
      );
    });

    for (final fixture in curatedSingleMessageCases) {
      test(
        '${fixture.category.name}:${fixture.id} stays on the expected conservative path',
        () async {
          final result = await ingestionUseCase.execute(<MessageRecord>[
            fixture.toMessage(receivedAt),
          ]);

          expect(
            fixture.protection,
            isNotEmpty,
            reason:
                'Each fixture should document what drift it protects against.',
          );
          expect(
            protectionForCategory(fixture.category),
            isNotEmpty,
            reason: 'Each category should stay explainable and documented.',
          );
          expect(result.events, hasLength(1));
          expect(result.events.single.type, fixture.expectedEventType);
          expect(result.events.single.serviceKey.value,
              fixture.expectedServiceKey);
          expect(result.ledgerEntries, hasLength(1));
          expect(result.ledgerEntries.single.serviceKey.value,
              fixture.expectedServiceKey);
          expect(result.ledgerEntries.single.state, fixture.expectedState);
          expect(result.ledgerEntries.single.totalBilled,
              fixture.expectedTotalBilled);
        },
      );
    }

    test('fragment identity cases surface a neutral unresolved title',
        () async {
      for (final fixture in <IndiaRealSmsRegressionCase>[
        dailyQuotaFragmentCase,
        truncatedAmpersandFragmentCase,
      ]) {
        final result = await ingestionUseCase.execute(<MessageRecord>[
          fixture.toMessage(receivedAt),
        ]);
        final cards = projection.buildCards(result.ledgerEntries);

        expect(cards, hasLength(1));
        expect(cards.single.title, 'Unresolved');
        expect(cards.single.title, isNot('Daily Quota As Per'));
        expect(cards.single.title, isNot('Day &'));
      }
    });

    test(
        'identity merge scenario keeps Adobe setup and billing on one service key',
        () async {
      final result = await ingestionUseCase.execute(
        identityMergeScenario.toMessages(receivedAt),
      );

      expect(identityMergeScenario.protection, isNotEmpty);
      expect(result.events, hasLength(2));
      expect(
        result.events.map((event) => event.type),
        containsAll(identityMergeScenario.cases
            .map((fixture) => fixture.expectedEventType)),
      );
      expect(result.ledgerEntries, hasLength(1));
      final adobeEntry = result.ledgerEntries.single;
      expect(adobeEntry.serviceKey.value, 'ADOBE_SYSTEMS');
      expect(adobeEntry.state, ResolverState.activePaid);
      expect(adobeEntry.totalBilled, 799);
      expect(
        adobeEntry.evidenceTrail.messageIds,
        containsAll(identityMergeScenario.cases.map((fixture) => fixture.id)),
      );
    });

    test('identity split scenario keeps distinct billed services separate',
        () async {
      final result = await ingestionUseCase.execute(
        identitySplitScenario.toMessages(receivedAt),
      );

      expect(identitySplitScenario.protection, isNotEmpty);
      expect(result.events, hasLength(2));
      expect(result.ledgerEntries, hasLength(2));
      expect(
        result.ledgerEntries.map((entry) => entry.serviceKey.value),
        containsAll(<String>['NETFLIX', 'YOUTUBE_PREMIUM']),
      );
      expect(
        result.ledgerEntries
            .every((entry) => entry.state == ResolverState.activePaid),
        isTrue,
      );
    });

    test(
        'repeated generic Google Play recurring billing stays merged in review',
        () async {
      final result = await ingestionUseCase.execute(
        repeatedGooglePlayReviewScenario.toMessages(receivedAt),
      );
      final reviewQueue = projection.buildReviewQueue(result.ledgerEntries);

      expect(repeatedGooglePlayReviewScenario.protection, isNotEmpty);
      expect(result.events, hasLength(2));
      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.serviceKey.value, 'GOOGLE_PLAY');
      expect(result.ledgerEntries.single.state,
          ResolverState.possibleSubscription);
      expect(
        result.ledgerEntries.single.evidenceTrail.messageIds,
        containsAll(
          repeatedGooglePlayReviewScenario.cases.map((fixture) => fixture.id),
        ),
      );
      expect(reviewQueue, hasLength(1));
      expect(reviewQueue.single.serviceKey.value, 'GOOGLE_PLAY');
    });

    test('mixed curated pack keeps dashboard high-signal and conservative',
        () async {
      final result = await ingestionUseCase.execute(
        curatedMixedPackScenario.toMessages(receivedAt),
      );
      final cards = projection.buildCards(result.ledgerEntries);
      final reviewQueue = projection.buildReviewQueue(result.ledgerEntries);

      expect(curatedMixedPackScenario.protection, isNotEmpty);
      // UNRESOLVED is intentionally excluded from active cards
      expect(
        cards
            .where(
                (card) => card.bucket == DashboardBucket.confirmedSubscriptions)
            .map((card) => card.serviceKey.value),
        containsAll(<String>[
          'NETFLIX',
          'SPOTIFY',
          'SWIGGY_ONE',
          'YOUTUBE_PREMIUM',
          'JIOHOTSTAR'
        ]),
      );
      expect(
        cards
            .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
            .map((card) => card.serviceKey.value),
        contains('GOOGLE_GEMINI_PRO'),
      );
      expect(
        cards
            .where((card) => card.bucket == DashboardBucket.needsReview)
            .map((card) => card.serviceKey.value),
        containsAll(<String>['CRUNCHYROLL', 'GOOGLE_PLAY']),
      );
      expect(reviewQueue, hasLength(2));
      expect(
        reviewQueue.map((item) => item.serviceKey.value),
        containsAll(<String>['CRUNCHYROLL', 'GOOGLE_PLAY']),
      );
      expect(
        result.ledgerEntries
            .where(_isHiddenNoise)
            .map((entry) => entry.serviceKey.value),
        everyElement('UNRESOLVED'),
      );
      expect(
        cards
            .where(
                (card) => card.bucket == DashboardBucket.confirmedSubscriptions)
            .length,
        5,
      );
    });
  });
}

bool _isHiddenNoise(ServiceLedgerEntry entry) {
  return entry.state == ResolverState.ignored ||
      entry.state == ResolverState.oneTimeOnly;
}
