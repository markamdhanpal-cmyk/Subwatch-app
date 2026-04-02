import '../enums/subscription_evidence_kind.dart';
import '../value_objects/service_key.dart';
import 'service_evidence_bucket.dart';
import 'subscription_evidence.dart';

class ServiceEvidenceAggregate {
  ServiceEvidenceAggregate({
    required this.serviceKey,
    required List<SubscriptionEvidence> evidences,
    required this.intervalHintsInDays,
    required this.amountSeries,
    required this.hasStrongMerchantMatch,
    required this.hasEndedLifecycleEvidence,
  }) : evidences = List<SubscriptionEvidence>.unmodifiable(evidences);

  factory ServiceEvidenceAggregate.fromBucket(ServiceEvidenceBucket bucket) {
    final evidences = <SubscriptionEvidence>[
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.paidCharge,
        count: bucket.billedCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.mandateSetup,
        count: bucket.mandateCount + bucket.autopaySetupCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.microVerification,
        count: bucket.microChargeCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.bundleBenefit,
        count: bucket.bundleCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.renewalHint,
        count: bucket.renewalHintCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.cancellationHint,
        count: bucket.cancellationHintCount + bucket.endedLifecycleCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.promoNoise,
        count: bucket.promoCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.otpNoise,
        count: bucket.otpNoiseCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.upiOneTime,
        count: bucket.oneTimePaymentNoiseCount,
      ),
      SubscriptionEvidence.aggregate(
        kind: SubscriptionEvidenceKind.telecomRechargeNoise,
        count: bucket.telecomRechargeNoiseCount,
      ),
    ].where((evidence) => evidence.count > 0).toList(growable: false);

    final hasStrongMerchantMatch = bucket.evidenceTrail.notes.any((note) {
      return note.startsWith('merchant_resolution:') &&
          (note.contains(':high:') || note.contains(':medium:'));
    });

    return ServiceEvidenceAggregate(
      serviceKey: bucket.serviceKey,
      evidences: evidences,
      intervalHintsInDays: bucket.intervalHintsInDays,
      amountSeries: bucket.amountSeries,
      hasStrongMerchantMatch: hasStrongMerchantMatch,
      hasEndedLifecycleEvidence: bucket.endedLifecycleCount > 0,
    );
  }

  final ServiceKey serviceKey;
  final List<SubscriptionEvidence> evidences;
  final List<int> intervalHintsInDays;
  final List<double> amountSeries;
  final bool hasStrongMerchantMatch;
  final bool hasEndedLifecycleEvidence;

  int count(SubscriptionEvidenceKind kind) {
    for (final evidence in evidences) {
      if (evidence.kind == kind) {
        return evidence.count;
      }
    }

    return 0;
  }

  bool get hasMonthlyPattern => intervalHintsInDays.any(
        (days) => days >= 27 && days <= 34,
      );

  bool get hasAnnualPattern => intervalHintsInDays.any(
        (days) => days >= 330 && days <= 390,
      );
}
