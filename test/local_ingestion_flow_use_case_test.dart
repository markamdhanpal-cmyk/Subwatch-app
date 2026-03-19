import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

void main() {
  group('LocalIngestionFlowUseCase', () {
    late LocalIngestionFlowUseCase useCase;
    final receivedAt = DateTime(2026, 3, 12, 22, 0);

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
      useCase = LocalIngestionFlowUseCase();
    });

    test('billed subscription becomes activePaid end to end', () async {
      final result = await useCase.execute(<MessageRecord>[
        message(
          id: 'netflix-1',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
      ]);

      expect(result.events, hasLength(1));
      expect(
          result.events.single.type, SubscriptionEventType.subscriptionBilled);
      expect(result.events.single.serviceKey.value, 'NETFLIX');
      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);
      expect(result.ledgerEntries.single.totalBilled, 499);
    });

    test('mandate created becomes pendingConversion end to end', () async {
      final result = await useCase.execute(<MessageRecord>[
        message(
          id: 'jio-1',
          body: 'You have successfully created a mandate on JioHotstar.',
        ),
      ]);

      expect(result.events.single.type, SubscriptionEventType.mandateCreated);
      expect(result.events.single.serviceKey.value, 'JIOHOTSTAR');
      expect(
          result.ledgerEntries.single.state, ResolverState.pendingConversion);
    });

    test('micro execution becomes verificationOnly end to end', () async {
      final result = await useCase.execute(<MessageRecord>[
        message(
          id: 'crunch-1',
          body:
              'Your mandate for Crunchyroll was successfully executed for Rs.1.00.',
        ),
      ]);

      expect(result.events.single.type,
          SubscriptionEventType.mandateExecutedMicro);
      expect(result.events.single.serviceKey.value, 'CRUNCHYROLL');
      expect(result.ledgerEntries.single.state, ResolverState.verificationOnly);
    });

    test('telecom bundle becomes activeBundled end to end', () async {
      final result = await useCase.execute(<MessageRecord>[
        message(
          id: 'airtel-1',
          body:
              'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
        ),
      ]);

      expect(result.events.single.type, SubscriptionEventType.bundleActivated);
      expect(result.events.single.serviceKey.value, 'GOOGLE_GEMINI_PRO');
      expect(result.ledgerEntries.single.state, ResolverState.activeBundled);
    });

    test('one-time payment noise does not become activePaid', () async {
      final result = await useCase.execute(<MessageRecord>[
        message(
          id: 'upi-1',
          body: 'Rs 1 debited via UPI to VPA test@upi.',
        ),
      ]);

      expect(result.events.single.type, SubscriptionEventType.oneTimePayment);
      expect(result.ledgerEntries.single.state, ResolverState.oneTimeOnly);
      expect(
          result.ledgerEntries.single.state, isNot(ResolverState.activePaid));
    });

    test('repeated messages for the same service update one ledger entry',
        () async {
      final result = await useCase.execute(<MessageRecord>[
        message(
          id: 'adobe-1',
          body:
              'Automatic payment of Rs.20,000 for Adobe Systems setup successfully.',
        ),
        message(
          id: 'adobe-2',
          body: 'Adobe plan renewed successfully. Rs 799 charged.',
        ),
      ]);

      expect(result.events, hasLength(2));
      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.serviceKey.value, 'ADOBE_SYSTEMS');
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);
      expect(result.ledgerEntries.single.totalBilled, 799);
    });

    test(
        'generic app-store recurring billing becomes reviewable instead of disappearing',
        () async {
      final result = await useCase.execute(<MessageRecord>[
        message(
          id: 'google-play-review-1',
          body:
              'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
        ),
      ]);

      expect(result.events, hasLength(1));
      expect(result.events.single.type, SubscriptionEventType.unknownReview);
      expect(result.events.single.serviceKey.value, 'GOOGLE_PLAY');
      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.state,
          ResolverState.possibleSubscription);
      expect(result.ledgerEntries.single.totalBilled, 0);
    });

    test('separate services remain separate end to end', () async {
      final result = await useCase.execute(<MessageRecord>[
        message(
          id: 'netflix-2',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'yt-1',
          body:
              'Your YouTube Premium monthly subscription payment of Rs 149 was successful.',
        ),
      ]);

      expect(result.ledgerEntries, hasLength(2));
      expect(
        result.ledgerEntries.map((entry) => entry.serviceKey.value),
        containsAll(<String>['NETFLIX', 'YOUTUBE_PREMIUM']),
      );
    });
  });
}
