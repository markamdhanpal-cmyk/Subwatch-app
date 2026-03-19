import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/classifiers/mandate_intent_classifier.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

void main() {
  group('MandateIntentClassifier', () {
    const classifier = MandateIntentClassifier();
    final receivedAt = DateTime(2026, 3, 12, 18, 30);

    MessageRecord message(String body) {
      return MessageRecord(
        id: body.hashCode.toString(),
        sourceAddress: 'BANK',
        body: body,
        receivedAt: receivedAt,
      );
    }

    test('classifies clear mandate creation intent', () {
      final result = classifier.classify(
        message('You have successfully created a mandate on JioHotstar.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.mandateCreated);
    });

    test('classifies automatic payment setup intent', () {
      final result = classifier.classify(
        message(
          'Automatic payment of Rs.20,000 for Adobe Systems setup successfully.',
        ),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.autopaySetup);
      expect(result.amount, 20000);
    });

    test('classifies mandate execution micro-hit', () {
      final result = classifier.classify(
        message(
          'Your mandate for Crunchyroll was successfully executed for Rs.1.00.',
        ),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.mandateExecutedMicro);
      expect(result.amount, 1);
    });

    test('parses rupees amount format for autopay setup', () {
      final result = classifier.classify(
        message(
            'Automatic payment of Rupees 99 for Adobe Systems setup enabled.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.autopaySetup);
      expect(result.amount, 99);
    });

    test('parses inr decimal amount format for mandate creation', () {
      final result = classifier.classify(
        message('eMandate created on JioHotstar for max amount INR 149.00.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.mandateCreated);
      expect(result.amount, 149);
    });

    test('does not classify tiny debit without recurring context', () {
      final result = classifier.classify(message('Rs 1 debited for chai.'));

      expect(result, isNull);
    });
  });
}
