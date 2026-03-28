import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/application/use_cases/project_review_queue_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/projections/deterministic_dashboard_projection.dart';

void main() {
  group('Weak signal review flow', () {
    late InMemoryLedgerRepository ledgerRepository;
    late LocalIngestionFlowUseCase ingestionUseCase;
    late ProjectReviewQueueUseCase reviewQueueUseCase;
    final receivedAt = DateTime(2026, 3, 12, 23, 0);

    MessageRecord message({
      required String id,
      required String body,
    }) {
      return MessageRecord(
        id: id,
        sourceAddress: 'SRC',
        body: body,
        receivedAt: receivedAt,
      );
    }

    setUp(() {
      ledgerRepository = InMemoryLedgerRepository();
      ingestionUseCase = LocalIngestionFlowUseCase(
        ledgerRepository: ledgerRepository,
      );
      reviewQueueUseCase = ProjectReviewQueueUseCase(
        ledgerRepository: ledgerRepository,
        dashboardProjection: const DeterministicDashboardProjection(),
      );
    });

    test(
      'unknownReview becomes possibleSubscription but is excluded from review queue if unresolved',
      () async {
        final result = await ingestionUseCase.execute(<MessageRecord>[
          message(
            id: 'weak-1',
            body: 'Your subscription may renew shortly.',
          ),
        ]);

        expect(result.events, hasLength(1));
        expect(result.events.single.type, SubscriptionEventType.unknownReview);
        expect(result.ledgerEntries, hasLength(1));
        expect(
          result.ledgerEntries.single.state,
          ResolverState.possibleSubscription,
        );

        final reviewItems = await reviewQueueUseCase.execute();

        expect(reviewItems, isEmpty);
      },
    );

    test(
        'membership payment reminder is excluded from review queue if unresolved',
        () async {
      await ingestionUseCase.execute(<MessageRecord>[
        message(
          id: 'weak-2',
          body: 'Your membership payment is due soon.',
        ),
      ]);

      final reviewItems = await reviewQueueUseCase.execute();

      expect(reviewItems, isEmpty);
    });

    test('confirmed paid subscription stays out of the review queue', () async {
      final result = await ingestionUseCase.execute(<MessageRecord>[
        message(
          id: 'netflix-weak-flow',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
      ]);

      expect(
          result.events.single.type, SubscriptionEventType.subscriptionBilled);
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);

      final reviewItems = await reviewQueueUseCase.execute();

      expect(reviewItems, isEmpty);
    });

    test('one-time UPI noise stays out of the review queue', () async {
      final result = await ingestionUseCase.execute(<MessageRecord>[
        message(
          id: 'upi-weak-flow',
          body: 'Rs 1 debited via UPI to VPA test@upi.',
        ),
      ]);

      expect(result.events.single.type, SubscriptionEventType.oneTimePayment);
      expect(result.ledgerEntries.single.state, ResolverState.oneTimeOnly);

      final reviewItems = await reviewQueueUseCase.execute();

      expect(reviewItems, isEmpty);
    });

    test(
      'mixed end-to-end flow excludes unresolved weak recurring items from review',
      () async {
        final result = await ingestionUseCase.execute(<MessageRecord>[
          message(
            id: 'weak-3',
            body: 'Your subscription may renew shortly.',
          ),
          message(
            id: 'weak-4',
            body: 'Your membership payment is due soon.',
          ),
          message(
            id: 'netflix-strong',
            body: 'Your Netflix subscription has been renewed for Rs 499.',
          ),
          message(
            id: 'airtel-bundle',
            body:
                'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
          ),
          message(
            id: 'upi-hidden',
            body: 'Rs 1 debited via UPI to VPA test@upi.',
          ),
        ]);

        expect(result.events, hasLength(5));

        final weakLedgerEntry = result.ledgerEntries.singleWhere(
          (entry) => entry.serviceKey.value == 'UNRESOLVED',
        );
        expect(weakLedgerEntry.state, ResolverState.possibleSubscription);

        final reviewItems = await reviewQueueUseCase.execute();

        expect(reviewItems, isEmpty);
      },
    );
  });
}
