import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/classifiers/weak_signal_review_classifier.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

void main() {
  group('WeakSignalReviewClassifier', () {
    const classifier = WeakSignalReviewClassifier();
    final receivedAt = DateTime(2026, 3, 12, 23, 0);

    MessageRecord message(String body) {
      return MessageRecord(
        id: body.hashCode.toString(),
        sourceAddress: 'SRC',
        body: body,
        receivedAt: receivedAt,
      );
    }

    test('classifies weak subscription reminder as unknownReview', () {
      final result = classifier.classify(
        message('Your subscription may renew shortly.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.unknownReview);
    });

    test('classifies weak recurring payment wording as unknownReview', () {
      final result = classifier.classify(
        message('Your recurring payment instruction is under process.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.unknownReview);
    });

    test('classifies membership set to renew as unknownReview', () {
      final result = classifier.classify(
        message('Your Amazon Prime membership is set to renew on March 15th.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.unknownReview);
    });

    test('classifies upcoming payment as unknownReview', () {
      final result = classifier.classify(
        message('You have an upcoming payment for your Google One plan.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.unknownReview);
    });

    test('classifies generic app-store recurring billing as unknownReview', () {
      final result = classifier.classify(
        message(
          'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
        ),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.unknownReview);
    });

    test('does not classify plain UPI noise', () {
      final result = classifier.classify(
        message('Rs 100 paid via UPI to merchant.'),
      );

      expect(result, isNull);
    });

    test('does not classify mandate setup', () {
      final result = classifier.classify(
        message(
            'Automatic payment of Rs.20,000 for Adobe Systems setup successfully.'),
      );

      expect(result, isNull);
    });

    test('does not classify micro execution', () {
      final result = classifier.classify(
        message(
            'Your mandate for Crunchyroll was successfully executed for Rs.1.00.'),
      );

      expect(result, isNull);
    });

    test('does not classify telecom bundle', () {
      final result = classifier.classify(
        message(
            'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.'),
      );

      expect(result, isNull);
    });

    test('does not classify strong billed subscription', () {
      final result = classifier.classify(
        message('Your Netflix subscription has been renewed for Rs 499.'),
      );

      expect(result, isNull);
    });

    test('does not classify direct card billing for a known recurring merchant',
        () {
      final result = classifier.classify(
        message('SBI Card XX4321 used for Rs 119 at SPOTIFY on 17 Mar.'),
      );

      expect(result, isNull);
    });
  });
}
