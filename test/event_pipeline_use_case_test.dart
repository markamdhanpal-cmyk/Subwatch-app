import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/event_pipeline_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

void main() {
  group('EventPipelineUseCase', () {
    final pipeline = EventPipelineUseCase();
    final receivedAt = DateTime(2026, 3, 12, 19, 30);

    MessageRecord message(String body) {
      return MessageRecord(
        id: body.hashCode.toString(),
        sourceAddress: 'SRC',
        body: body,
        receivedAt: receivedAt,
      );
    }

    test('resolves UPI noise through the pipeline', () {
      final result = pipeline.classify(
        message('Rs 1 debited via UPI to VPA test@upi. Ref 2222'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.oneTimePayment);
      expect(result.classifierId, 'merged_event_pipeline');
    });

    test('resolves mandate intent through the pipeline', () {
      final result = pipeline.classify(
        message('You have successfully created a mandate on JioHotstar.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.mandateCreated);
      expect(result.classifierId, 'mandate_intent');
    });

    test('resolves telecom bundle detection through the pipeline', () {
      final result = pipeline.classify(
        message(
          'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
        ),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.bundleActivated);
      expect(result.classifierId, 'telecom_bundle');
    });

    test('resolves strong billed subscription evidence through the pipeline',
        () {
      final result = pipeline.classify(
        message('Your Netflix subscription has been renewed for Rs 499.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.classifierId, 'subscription_billed');
    });

    test('routes weak recurring reminder through unknownReview last', () {
      final result = pipeline.classify(
        message('Your subscription may renew shortly.'),
      );

      expect(result, isNull);
    });

    test('executes with deterministic service identity resolution', () {
      final events = pipeline.execute(<MessageRecord>[
        message('Your Netflix subscription has been renewed for Rs 499.'),
      ]);

      expect(events, hasLength(1));
      expect(events.single.serviceKey.value, 'NETFLIX');
      expect(events.single.merchantResolution, isNotNull);
      expect(events.single.merchantResolution!.resolvedServiceKey.value,
          'NETFLIX');
      expect(
        events.single.evidenceTrail.notes,
        contains(startsWith('merchant_resolution:exactAlias:high:')),
      );
    });

    test('returns null for unmatched generic message', () {
      final result =
          pipeline.classify(message('Hello, your profile was updated.'));

      expect(result, isNull);
    });
  });
}
