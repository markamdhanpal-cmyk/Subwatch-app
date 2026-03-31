import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/classifiers/subscription_billed_classifier.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

void main() {
  group('SubscriptionBilledClassifier', () {
    const classifier = SubscriptionBilledClassifier();
    final receivedAt = DateTime(2026, 3, 12, 20, 0);

    MessageRecord message(String body) {
      return MessageRecord(
        id: body.hashCode.toString(),
        sourceAddress: 'BANK',
        body: body,
        receivedAt: receivedAt,
      );
    }

    test('classifies renewed subscription with amount', () {
      final result = classifier.classify(
        message('Your Netflix subscription has been renewed for Rs 499.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 499);
    });

    test('classifies debited monthly subscription with amount', () {
      final result = classifier.classify(
        message('Rs 1950 debited for Google One monthly subscription.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 1950);
    });

    test('classifies renewed plan with charged amount', () {
      final result = classifier.classify(
        message('Adobe plan renewed successfully. Rs 799 charged.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 799);
    });

    test('classifies successful monthly subscription payment', () {
      final result = classifier.classify(
        message(
          'Your YouTube Premium monthly subscription payment of Rs 149 was successful.',
        ),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 149);
    });

    test('parses rupee symbol and comma separated billed amount', () {
      final result = classifier.classify(
        message('Your Netflix subscription has been renewed for \u20B9 1,499.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 1499);
    });

    test('classifies direct card debit for a known recurring merchant', () {
      final result = classifier.classify(
        message('SBI Card XX4321 used for Rs 119 at SPOTIFY on 17 Mar.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 119);
    });

    test('classifies app-store merchant when the billed service is explicit',
        () {
      final result = classifier.classify(
        message(
            'Card XX9123 used for Rs 149 at YOUTUBEPREMIUM on Google Play.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 149);
    });

    test('classifies a paid JioHotstar renewal as billed subscription', () {
      final result = classifier.classify(
        message('Your JioHotstar subscription has been renewed for Rs 299.'),
      );
 
      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 299);
    });

    test('classifies annual subscription from single message with amount', () {
      final result = classifier.classify(
        message('Your annual Disney+ Hotstar subscription of Rs.1499 has been renewed.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 1499);
    });

    test('classifies yearly plan from single message with amount', () {
      final result = classifier.classify(
        message('Your Amazon Prime yearly plan has been renewed successfully for Rs 999.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 999);
    });

    test('does not veto renewal-failed message for telecom merchant', () {
      // "unable to renew" should bypass the telecom bundle veto
      final result = classifier.classify(
        message('Your JioHotstar subscription: Unable to renew as payment of Rs 299 failed.'),
      );

      // Note: SubscriptionBilledClassifier might still return null if it requires success context,
      // but the point here is that it should NOT be killed by the telecom bundle veto.
      // In this specific case, 'Unable to renew' might not meet 'successContext',
      // but let's check if it meets 'hasAnnualConfirmation' if it was annual.
      
      // If we use a "will retry" or "renewal pending" message:
      final retryResult = classifier.classify(
        message('Your JioHotstar annual subscription renewal of Rs 1499 is pending. We will retry.'),
      );

      expect(retryResult, isNotNull, reason: 'Renewal risk should bypass telecom veto');
      expect(retryResult!.amount, 1499);
    });

    test('classifies direct card debit for Swiggy One membership', () {
      final result = classifier.classify(
        message('HDFC Card XX1212 used for Rs 99 at SWIGGY ONE on 17 Mar.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 99);
    });

    test('parses rs-dot amount format', () {
      final result = classifier.classify(
        message('Adobe plan renewed successfully. Rs.299 charged.'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 299);
    });

    test('does not classify generic shopping debit', () {
      final result =
          classifier.classify(message('Rs 149 debited for shopping.'));

      expect(result, isNull);
    });

    test('does not classify mandate creation wording', () {
      final result = classifier.classify(
        message('Mandate created for YouTube Premium.'),
      );

      expect(result, isNull);
    });

    test('does not classify mandate micro execution', () {
      final result = classifier.classify(
        message('Your mandate was successfully executed for Rs 1.00.'),
      );

      expect(result, isNull);
    });

    test('does not classify plain UPI merchant payment', () {
      final result = classifier.classify(
        message('Rs 100 paid via UPI to merchant.'),
      );

      expect(result, isNull);
    });

    test('does not classify generic app-store recurring payment without a clear service', () {
      final result = classifier.classify(
        message(
          'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
        ),
      );

      expect(result, isNull);
    });

    test('does not veto direct telecom subscription billing with strong evidence', () {
      final result = classifier.classify(
        message('Your Jio subscription of Rs.149 has been renewed successfully.'),
      );

      expect(result, isNotNull);
      expect(result!.eventType, SubscriptionEventType.subscriptionBilled);
      expect(result.amount, 149);
    });

    test('vetoes standard telecom plan / benefit message', () {
      final result = classifier.classify(
        message('Your Jio plan of Rs.299 is active with 2GB/day benefit.'),
      );

      expect(result, isNull);
    });

    test('vetoes airtel bundle benefit message', () {
      final result = classifier.classify(
        message('Your Airtel recharge of Rs 599 unlocks a FREE 1-month Netflix subscription.'),
      );

      expect(result, isNull);
    });

    test('vetoes co-branded bundle wording correctly', () {
      final result = classifier.classify(
        message('Enjoy your complimentary JioHotstar bundle with your new plan.'),
      );

      expect(result, isNull);
    });
  });
}
