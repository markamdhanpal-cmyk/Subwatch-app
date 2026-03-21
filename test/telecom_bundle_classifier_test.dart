import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/classifiers/telecom_bundle_classifier.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

void main() {
  group('TelecomBundleClassifier', () {
    const classifier = TelecomBundleClassifier();
    final receivedAt = DateTime(2026, 3, 12, 19, 0);

    MessageRecord message(String body) {
      return MessageRecord(
        id: body.hashCode.toString(),
        sourceAddress: 'TELCO',
        body: body,
        receivedAt: receivedAt,
      );
    }

    test('classifies telecom subscription unlocked by recharge', () {
      final result = classifier.classify(
        message(
          'Your 1-month JioHotstar subscription is now activated. Your recent recharge has unlocked this benefit.',
        ),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.bundleActivated);
    });

    test('classifies free telecom plan benefit', () {
      final result = classifier.classify(
        message(
          'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
        ),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.bundleActivated);
    });

    test('does not classify generic activation without telecom context', () {
      final result = classifier.classify(message('Your account is activated.'));

      expect(result, isNull);
    });

    test('does not classify activation without telecom provider context', () {
      final result = classifier.classify(
        message('Your 1-month music subscription is now activated.'),
      );

      expect(result, isNull);
    });
    test('does not classify a paid JioHotstar renewal as a telecom bundle', () {
      final result = classifier.classify(
        message('Your JioHotstar subscription has been renewed for Rs 299.'),
      );

      expect(result, isNull);
    });
  });
}
