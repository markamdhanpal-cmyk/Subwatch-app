import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/entities/subscription_evidence.dart';
import 'package:sub_killer/domain/enums/merchant_resolution_confidence.dart';
import 'package:sub_killer/domain/enums/merchant_resolution_method.dart';
import 'package:sub_killer/domain/enums/subscription_evidence_kind.dart';
import 'package:sub_killer/domain/services/service_key_resolver_v2.dart';

void main() {
  group('ServiceKeyResolverV2', () {
    const resolver = ServiceKeyResolverV2();
    final occurredAt = DateTime(2026, 3, 30, 12, 0);

    MessageRecord message({required String sender, required String body}) {
      return MessageRecord(
        id: body.hashCode.toString(),
        sourceAddress: sender,
        body: body,
        receivedAt: occurredAt,
      );
    }

    SubscriptionEvidence evidence(SubscriptionEvidenceKind kind) {
      return SubscriptionEvidence(
        messageId: 'msg',
        kind: kind,
        occurredAt: occurredAt,
      );
    }

    test('keeps unknown paid-plan merchant text unresolved', () {
      final resolution = resolver.resolve(
        message: message(
          sender: 'VK-HDFCBK-S',
          body: 'Your Music Plus plan renewed successfully. Rs 149 charged.',
        ),
        evidence: evidence(SubscriptionEvidenceKind.paidCharge),
      );

      expect(
        resolution.resolvedServiceKey.value,
        ServiceKeyResolverV2.unresolvedServiceKey.value,
      );
      expect(resolution.resolutionMethod, MerchantResolutionMethod.noMatch);
    });

    test('keeps unknown mandate merchant text unresolved (MODI FINANCE case)', () {
      final resolution = resolver.resolve(
        message: message(
          sender: 'VM-FEDBNK-S',
          body:
              'Dear Customer, You have successfully created a mandate on MODI FINANCE for a maximum amount of Rs 2868.00 - Federal Bank',
        ),
        evidence: evidence(SubscriptionEvidenceKind.mandateSetup),
      );

      expect(
        resolution.resolvedServiceKey.value,
        ServiceKeyResolverV2.unresolvedServiceKey.value,
      );
    });

    test('resolves sender-prefix aliases even when body is weak', () {
      final resolution = resolver.resolve(
        message: message(
          sender: 'AD-JIOHTT-S',
          body: 'Your subscription was renewed.',
        ),
        evidence: evidence(SubscriptionEvidenceKind.paidCharge),
      );

      expect(resolution.resolvedServiceKey.value, 'JIOHOTSTAR');
      expect(
        resolution.resolutionMethod,
        MerchantResolutionMethod.senderIdPrefix,
      );
      expect(resolution.confidence, MerchantResolutionConfidence.high);
    });

    test('unrelated sender prefix does not falsely resolve', () {
      final resolution = resolver.resolve(
        message: message(
          sender: 'JY-JIOINF-S',
          body: 'Your subscription was renewed.',
        ),
        evidence: evidence(SubscriptionEvidenceKind.paidCharge),
      );

      expect(
        resolution.resolvedServiceKey.value,
        ServiceKeyResolverV2.unresolvedServiceKey.value,
      );
      expect(resolution.resolutionMethod, MerchantResolutionMethod.noMatch);
    });

    test(
        'keeps telecom generic data-plan wording unresolved instead of generating synthetic keys',
        () {
      final resolution = resolver.resolve(
        message: message(
          sender: 'JY-JIOPAY-S',
          body:
              'ATTENTION! If you do not have any other data plan then your internet speed will be reduced once 100% of data quota is used.',
        ),
        evidence: evidence(SubscriptionEvidenceKind.telecomRechargeNoise),
      );

      expect(
        resolution.resolvedServiceKey.value,
        ServiceKeyResolverV2.unresolvedServiceKey.value,
      );
    });

    test('resolves known recurring merchant aliases when evidence is clear', () {
      final resolution = resolver.resolve(
        message: message(
          sender: 'VK-HDFCBK-S',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        evidence: evidence(SubscriptionEvidenceKind.paidCharge),
      );

      expect(resolution.resolvedServiceKey.value, 'NETFLIX');
      expect(resolution.resolutionMethod, MerchantResolutionMethod.exactAlias);
    });
  });
}

