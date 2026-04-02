import '../entities/service_evidence_aggregate.dart';
import '../enums/service_decision_state.dart';
import '../enums/subscription_evidence_kind.dart';

class SubscriptionDecisionEngineV3 {
  const SubscriptionDecisionEngineV3();

  ServiceDecisionState decide(ServiceEvidenceAggregate aggregate) {
    final paidCount = aggregate.count(SubscriptionEvidenceKind.paidCharge);
    final bundleCount = aggregate.count(SubscriptionEvidenceKind.bundleBenefit);
    final mandateCount = aggregate.count(SubscriptionEvidenceKind.mandateSetup);
    final microCount =
        aggregate.count(SubscriptionEvidenceKind.microVerification);
    final renewalHintCount =
        aggregate.count(SubscriptionEvidenceKind.renewalHint);
    final cancellationHintCount =
        aggregate.count(SubscriptionEvidenceKind.cancellationHint);
    final promoNoiseCount = aggregate.count(SubscriptionEvidenceKind.promoNoise);
    final otpNoiseCount = aggregate.count(SubscriptionEvidenceKind.otpNoise);
    final oneTimeCount = aggregate.count(SubscriptionEvidenceKind.upiOneTime);
    final telecomNoiseCount =
        aggregate.count(SubscriptionEvidenceKind.telecomRechargeNoise);

    final hasPaidEvidence = paidCount > 0;
    final hasBundleEvidence = bundleCount > 0;
    final hasSetupOnlyEvidence = mandateCount > 0 || microCount > 0;
    final hasRecurringCadence =
        aggregate.hasMonthlyPattern || aggregate.hasAnnualPattern;
    final hasSingleStrongAnnualCharge =
        paidCount == 1 &&
            aggregate.hasStrongMerchantMatch &&
            _hasCredibleAnnualSingleCharge(aggregate);

    if (hasPaidEvidence &&
        aggregate.hasStrongMerchantMatch &&
        !hasBundleEvidence &&
        (hasRecurringCadence || hasSingleStrongAnnualCharge)) {
      return ServiceDecisionState.confirmedPaid;
    }

    if (hasBundleEvidence && !hasPaidEvidence) {
      return ServiceDecisionState.includedWithPlan;
    }

    if (hasSetupOnlyEvidence && !hasPaidEvidence) {
      return ServiceDecisionState.setupOnly;
    }

    if (aggregate.hasEndedLifecycleEvidence ||
        (cancellationHintCount > 0 && !hasPaidEvidence && !hasBundleEvidence)) {
      return ServiceDecisionState.ended;
    }

    if (hasPaidEvidence ||
        renewalHintCount > 0 ||
        cancellationHintCount > 0 ||
        hasSetupOnlyEvidence) {
      return ServiceDecisionState.possibleButUnconfirmed;
    }

    if (promoNoiseCount > 0 ||
        otpNoiseCount > 0 ||
        oneTimeCount > 0 ||
        telecomNoiseCount > 0) {
      return ServiceDecisionState.hiddenNoise;
    }

    return ServiceDecisionState.hiddenNoise;
  }

  bool _hasCredibleAnnualSingleCharge(ServiceEvidenceAggregate aggregate) {
    if (aggregate.amountSeries.length != 1) {
      return false;
    }

    final amount = aggregate.amountSeries.single;
    return amount >= 600;
  }
}
