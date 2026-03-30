class SubscriptionScoringFeatures {
  const SubscriptionScoringFeatures({
    required this.featureSchemaVersion,
    required this.billedEvidenceCount,
    required this.renewalHintCount,
    required this.mandateEvidenceCount,
    required this.autopaySetupCount,
    required this.microChargeCount,
    required this.bundleEvidenceCount,
    required this.promoEvidenceCount,
    required this.cancellationHintCount,
    required this.weakRecurringHintCount,
    required this.unknownReviewCount,
    required this.contradictionCount,
    required this.sourceTrustScore,
    required this.merchantConfidenceScore,
    required this.intervalStabilityScore,
    required this.amountStabilityScore,
    required this.userConfirmedCount,
    required this.userRejectedCount,
    required this.userMarkedBenefitCount,
  });

  final int featureSchemaVersion;
  final int billedEvidenceCount;
  final int renewalHintCount;
  final int mandateEvidenceCount;
  final int autopaySetupCount;
  final int microChargeCount;
  final int bundleEvidenceCount;
  final int promoEvidenceCount;
  final int cancellationHintCount;
  final int weakRecurringHintCount;
  final int unknownReviewCount;
  final int contradictionCount;
  final double sourceTrustScore;
  final double merchantConfidenceScore;
  final double intervalStabilityScore;
  final double amountStabilityScore;
  final int userConfirmedCount;
  final int userRejectedCount;
  final int userMarkedBenefitCount;
}
