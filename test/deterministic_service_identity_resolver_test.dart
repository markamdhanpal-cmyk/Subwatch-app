import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/entities/parsed_signal.dart';
import 'package:sub_killer/domain/enums/merchant_resolution_confidence.dart';
import 'package:sub_killer/domain/enums/merchant_resolution_method.dart';
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

    test('keeps unknown plan names unresolved without exact alias evidence',
        () {
      final resolution = resolver.resolveMerchant(
        message: message(
          'Your Music Plus plan renewed successfully. Rs 149 charged.',
        ),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(
        resolution.resolvedServiceKey.value,
        DeterministicServiceIdentityResolver.unresolvedServiceKey.value,
      );
      expect(resolution.resolutionMethod, MerchantResolutionMethod.noMatch);
    });

    test('resolves JioHotstar from sender ID prefix even with weak body', () {
      final messageRecord = MessageRecord(
        id: '123',
        sourceAddress: 'AD-JIOHTT-S',
        body: 'Your subscription was renewed.',
        receivedAt: receivedAt,
      );
      final resolution = resolver.resolveMerchant(
        message: messageRecord,
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(resolution.resolvedServiceKey.value, 'JIOHOTSTAR');
      expect(
          resolution.resolutionMethod, MerchantResolutionMethod.senderIdPrefix);
      expect(resolution.confidence, MerchantResolutionConfidence.high);
    });

    test('resolves Netflix via body when sender prefix does not match', () {
      final messageRecord = MessageRecord(
        id: '124',
        sourceAddress: 'BZ-UNKNOWN',
        body: 'Your Netflix subscription has been renewed for Rs 499.',
        receivedAt: receivedAt,
      );
      final resolution = resolver.resolveMerchant(
        message: messageRecord,
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(resolution.resolvedServiceKey.value, 'NETFLIX');
      expect(resolution.resolutionMethod, MerchantResolutionMethod.exactAlias);
    });

    test('unrelated sender prefix does not falsely resolve', () {
      final messageRecord = MessageRecord(
        id: '125',
        sourceAddress: 'JY-JIOINF',
        body: 'Your subscription was renewed.',
        receivedAt: receivedAt,
      );
      final resolution = resolver.resolveMerchant(
        message: messageRecord,
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(resolution.resolvedServiceKey.value, isNot('JIOHOTSTAR'));
      expect(resolution.resolutionMethod,
          isNot(MerchantResolutionMethod.senderIdPrefix));
    });

    test('keeps strong billed subscription identity unchanged', () {
      final key = resolver.resolve(
        message:
            message('Your Netflix subscription has been renewed for Rs 499.'),
        signal: signal(SubscriptionEventType.subscriptionBilled),
      );

      expect(key.value, 'NETFLIX');
    });

    test('keeps unknown mandate merchant text unresolved (MODI FINANCE case)',
        () {
      final resolution = resolver.resolveMerchant(
        message: MessageRecord(
          id: '126',
          sourceAddress: 'VM-FEDBNK-S',
          body:
              'Dear Customer, You have successfully created a mandate on MODI FINANCE for a maximum amount of Rs 2868.00 - Federal Bank',
          receivedAt: receivedAt,
        ),
        signal: signal(SubscriptionEventType.mandateCreated),
      );

      expect(
        resolution.resolvedServiceKey.value,
        DeterministicServiceIdentityResolver.unresolvedServiceKey.value,
      );
      expect(resolution.resolutionMethod, MerchantResolutionMethod.noMatch);
    });

    test(
        'keeps telecom generic data-plan warning unresolved instead of synthetic keying',
        () {
      final resolution = resolver.resolveMerchant(
        message: MessageRecord(
          id: '127',
          sourceAddress: 'JY-JIOPAY-S',
          body:
              'ATTENTION! If you do not have any other data plan then your internet speed will be reduced once 100% of data quota is used.',
          receivedAt: receivedAt,
        ),
        signal: signal(SubscriptionEventType.ignore),
      );

      expect(
        resolution.resolvedServiceKey.value,
        DeterministicServiceIdentityResolver.unresolvedServiceKey.value,
      );
      expect(resolution.resolutionMethod, MerchantResolutionMethod.protectedUnresolved);
    });
  });
}
