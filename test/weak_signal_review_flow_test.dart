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

    test('unresolved weak reminders stay hidden and do not create review load',
        () async {
      final result = await ingestionUseCase.execute(<MessageRecord>[
        message(
          id: 'weak-1',
          body: 'Your subscription may renew shortly.',
        ),
      ]);

      expect(result.events, isEmpty);
      expect(result.ledgerEntries, isEmpty);

      final reviewItems = await reviewQueueUseCase.execute();
      expect(reviewItems, isEmpty);
    });

    test('membership payment reminder is kept hidden without billed proof',
        () async {
      final result = await ingestionUseCase.execute(<MessageRecord>[
        message(
          id: 'weak-2',
          body: 'Your membership payment is due soon.',
        ),
      ]);

      expect(result.events, isEmpty);
      expect(result.ledgerEntries, isEmpty);

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

      expect(result.events.single.type, SubscriptionEventType.subscriptionBilled);
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

      expect(result.events, hasLength(1));
      expect(result.events.single.type, SubscriptionEventType.oneTimePayment);
      expect(result.ledgerEntries, isEmpty);

      final reviewItems = await reviewQueueUseCase.execute();
      expect(reviewItems, isEmpty);
    });

    test('mixed flow keeps weak reminders hidden and preserves trusted paid-vs-included separation',
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

      expect(result.events, hasLength(3));
      expect(
        result.events.map((event) => event.type),
        containsAll(<SubscriptionEventType>[
          SubscriptionEventType.subscriptionBilled,
          SubscriptionEventType.bundleActivated,
          SubscriptionEventType.oneTimePayment,
        ]),
      );

      expect(result.ledgerEntries, hasLength(2));
      expect(
        result.ledgerEntries
            .where((entry) => entry.state == ResolverState.activePaid)
            .map((entry) => entry.serviceKey.value),
        contains('NETFLIX'),
      );
      expect(
        result.ledgerEntries
            .where((entry) => entry.state == ResolverState.activeBundled)
            .map((entry) => entry.serviceKey.value),
        contains('GOOGLE_GEMINI_PRO'),
      );

      final reviewItems = await reviewQueueUseCase.execute();
      expect(reviewItems, isEmpty);
    });
  });
}


