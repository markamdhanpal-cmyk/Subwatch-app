import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/classifiers/upi_noise_veto_classifier.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

void main() {
  group('UpiNoiseVetoClassifier', () {
    const classifier = UpiNoiseVetoClassifier();
    final receivedAt = DateTime(2026, 3, 12, 18, 0);

    MessageRecord message(String body) {
      return MessageRecord(
        id: body.hashCode.toString(),
        sourceAddress: 'BANK',
        body: body,
        receivedAt: receivedAt,
      );
    }

    test('classifies BharatPe-style UPI transfer noise as ignore', () {
      final result = classifier.classify(
        message('Rs 250 sent via UPI to BharatPe merchant. Ref 1234'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.ignore);
      expect(result.amount, 250);
    });

    test(
        'classifies plain UPI debit to VPA as non-subscription one-time payment',
        () {
      final result = classifier.classify(
        message('Rs 1 debited via UPI to VPA test@upi. Ref 2222'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.oneTimePayment);
      expect(result.amount, isNull);
    });

    test('parses rupee symbol amount in UPI noise', () {
      final result = classifier.classify(
        message('\u20B9299 sent via UPI to BharatPe merchant. Ref 1234'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.ignore);
      expect(result.amount, 299);
    });

    test('parses inr decimal amount in UPI debit noise', () {
      final result = classifier.classify(
        message('INR 149.00 debited via UPI to VPA test@upi. Ref 2222'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.oneTimePayment);
      expect(result.amount, 149);
    });

    test('does not veto when mandate wording is present', () {
      final result = classifier.classify(
        message('Mandate created for JioHotstar. Rs 1 debited via UPI.'),
      );

      expect(result, isNull);
    });

    test('does not veto when autopay wording is present', () {
      final result = classifier.classify(
        message('Autopay for YouTube Premium. Rs 149 debited via UPI.'),
      );

      expect(result, isNull);
    });
  });
}

