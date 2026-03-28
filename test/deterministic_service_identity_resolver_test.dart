import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/entities/parsed_signal.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/resolvers/deterministic_service_identity_resolver.dart';

void main() {
  group('DeterministicServiceIdentityResolver', () {
    const resolver = DeterministicServiceIdentityResolver();
    final receivedAt = DateTime(2026, 3, 12, 20, 30);

    MessageRecord message(String body) {
      return MessageRecord(
        id: body.hashCode.toString(),
        sourceAddress: 'SRC',
        body: body,
        receivedAt: receivedAt,
      );
    }

    ParsedSignal signal(SubscriptionEventType eventType) {
      return ParsedSignal(
        classifierId: 'test',
        eventType: eventType,
        summary: 'test signal',
        detectedAt: receivedAt,
      );
    }

    test('resolves Netflix to a stable key', () {
      final key = resolver.resolve(
        message:
            message('Your Netflix subscription has been renewed for Rs 499.'),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'NETFLIX');
    });

    test('resolves YouTube Premium to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'Your YouTube Premium monthly subscription payment of Rs 149 was successful.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'YOUTUBE_PREMIUM');
    });

    test('resolves Apple Music to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'Your Apple Music plan renewed successfully. Rs 99 charged.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'APPLE_MUSIC');
    });

    test('resolves Apple Music card billing to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'Card XX8821 used for Rs 99 at APPLE MUSIC on 17 Mar.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'APPLE_MUSIC');
    });

    test('resolves Spotify card billing to a stable key', () {
      final key = resolver.resolve(
        message:
            message('SBI Card XX4321 used for Rs 119 at SPOTIFY on 17 Mar.'),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'SPOTIFY');
    });

    test('resolves Adobe Systems to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'Automatic payment of Rs.20,000 for Adobe Systems setup successfully.',
        ),
        signal: signal(SubscriptionEventType.autopaySetup),
      );

      expect(key.value, 'ADOBE_SYSTEMS');
    });

    test('resolves JioHotstar bundle to a deterministic key', () {
      final key = resolver.resolve(
        message: message(
          'Your 1-month JioHotstar subscription is now activated. Your recent recharge has unlocked this benefit.',
        ),
        signal: signal(SubscriptionEventType.bundleActivated),
      );

      expect(key.value, 'JIOHOTSTAR');
    });

    test('resolves Disney Hotstar card billing to JioHotstar', () {
      final key = resolver.resolve(
        message: message(
          'HDFC Card XX4411 used for Rs 299 at DISNEY+ HOTSTAR on 17 Mar.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'JIOHOTSTAR');
    });

    test('resolves Swiggy One card billing to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'HDFC Card XX1212 used for Rs 99 at SWIGGY ONE on 17 Mar.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'SWIGGY_ONE');
    });

    test('resolves SonyLIV card billing to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'ICICI Card XX2121 used for Rs 299 at SONYLIV on 17 Mar.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'SONYLIV');
    });

    test('keeps weak generic message unresolved', () {
      final key = resolver.resolve(
        message: message('Rs 100 debited for shopping.'),
        signal: signal(SubscriptionEventType.oneTimePayment),
      );

      expect(key.value,
          DeterministicServiceIdentityResolver.unresolvedServiceKey.value);
    });

    test('resolves Amazon Prime weak review message to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'Your Amazon Prime membership is set to renew on March 15th.',
        ),
        signal: signal(SubscriptionEventType.unknownReview),
      );

      expect(key.value, 'AMAZON_PRIME');
    });

    test('resolves Google One weak review message to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'You have an upcoming payment for your Google One plan.',
        ),
        signal: signal(SubscriptionEventType.unknownReview),
      );

      expect(key.value, 'GOOGLE_ONE');
    });

    test('resolves Google Play recurring review message to a stable key', () {
      final key = resolver.resolve(
        message: message(
          'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
        ),
        signal: signal(SubscriptionEventType.unknownReview),
      );

      expect(key.value, 'GOOGLE_PLAY');
    });

    test('keeps generic weak subscription reminder unresolved', () {
      final key = resolver.resolve(
        message: message('Your subscription may renew shortly.'),
        signal: signal(SubscriptionEventType.unknownReview),
      );

      expect(key.value,
          DeterministicServiceIdentityResolver.unresolvedServiceKey.value);
    });

    test('keeps generic membership payment reminder unresolved', () {
      final key = resolver.resolve(
        message: message('Your membership payment is due soon.'),
        signal: signal(SubscriptionEventType.unknownReview),
      );

      expect(key.value,
          DeterministicServiceIdentityResolver.unresolvedServiceKey.value);
    });

    test('downgrades daily quota fragment candidate to unresolved', () {
      final key = resolver.resolve(
        message: message(
          'Your Daily Quota As Per plan renewed successfully. Rs 249 charged.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value,
          DeterministicServiceIdentityResolver.unresolvedServiceKey.value);
      expect(key.displayName, 'Unresolved');
    });

    test('downgrades truncated ampersand fragment candidate to unresolved', () {
      final key = resolver.resolve(
        message: message(
          'Your 7 Day & plan renewed successfully. Rs 99 charged.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value,
          DeterministicServiceIdentityResolver.unresolvedServiceKey.value);
      expect(key.displayName, 'Unresolved');
    });

    test(
        'keeps a human-credible extracted plan name when no explicit hint exists',
        () {
      final key = resolver.resolve(
        message: message(
          'Your Music Plus plan renewed successfully. Rs 149 charged.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'MUSIC_PLUS');
    });

    test('keeps strong billed subscription identity unchanged', () {
      final key = resolver.resolve(
        message:
            message('Your Netflix subscription has been renewed for Rs 499.'),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'NETFLIX');
    });
  });
}
