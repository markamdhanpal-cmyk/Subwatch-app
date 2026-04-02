import '../../../domain/entities/service_evidence_bucket.dart';
import '../../../domain/entities/subscription_evidence.dart';
import '../../../domain/enums/subscription_evidence_kind.dart';
import '../models/service_evidence_profile.dart';

class BuildServiceEvidenceProfileUseCase {
  const BuildServiceEvidenceProfileUseCase();

  ServiceEvidenceProfile execute(ServiceEvidenceBucket bucket) {
    final evidences = <SubscriptionEvidence>[
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.paidCharge,
        occurredAt: null,
        count: bucket.billedCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.mandateSetup,
        occurredAt: null,
        count: bucket.mandateCount + bucket.autopaySetupCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.microVerification,
        occurredAt: null,
        count: bucket.microChargeCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.bundleBenefit,
        occurredAt: null,
        count: bucket.bundleCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.renewalHint,
        occurredAt: null,
        count: bucket.renewalHintCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.cancellationHint,
        occurredAt: null,
        count: bucket.cancellationHintCount + bucket.endedLifecycleCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.promoNoise,
        occurredAt: null,
        count: bucket.promoCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.otpNoise,
        occurredAt: null,
        count: bucket.otpNoiseCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.upiOneTime,
        occurredAt: null,
        count: bucket.oneTimePaymentNoiseCount,
      ),
      SubscriptionEvidence(
        messageId: '',
        kind: SubscriptionEvidenceKind.telecomRechargeNoise,
        occurredAt: null,
        count: bucket.telecomRechargeNoiseCount,
      ),
    ].where((evidence) => evidence.count > 0).toList(growable: false)
      ..sort((left, right) => left.kind.index.compareTo(right.kind.index));

    return ServiceEvidenceProfile(
      serviceKey: bucket.serviceKey,
      evidences: evidences,
    );
  }
}
