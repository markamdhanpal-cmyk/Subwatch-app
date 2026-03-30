import '../../../domain/entities/service_evidence_bucket.dart';
import '../../scoring/contracts/subscription_scorer.dart';
import '../../scoring/models/subscription_score.dart';
import '../../scoring/models/subscription_scoring_context.dart';
import '../../scoring/use_cases/local_subscription_scorer.dart';
import '../enums/decision_band.dart';
import '../enums/decision_reason_code.dart';
import '../models/decision_snapshot.dart';

class DecisionEngineV2UseCase {
  const DecisionEngineV2UseCase({
    SubscriptionScorer scorer = const LocalSubscriptionScorer(),
  }) : _scorer = scorer;

  final SubscriptionScorer _scorer;

  List<DecisionSnapshot> decideAll(
    Iterable<ServiceEvidenceBucket> buckets, {
    Map<String, SubscriptionScoringContext> scoringContextsByServiceKey =
        const <String, SubscriptionScoringContext>{},
  }) {
    final snapshots = buckets
        .map(
          (bucket) => decide(
            bucket,
            scoringContext:
                scoringContextsByServiceKey[bucket.serviceKey.value] ??
                    const SubscriptionScoringContext(),
          ),
        )
        .toList(growable: false)
      ..sort(
        (left, right) =>
            left.serviceKey.value.compareTo(right.serviceKey.value),
      );
    return snapshots;
  }

  DecisionSnapshot decide(
    ServiceEvidenceBucket bucket, {
    SubscriptionScoringContext scoringContext =
        const SubscriptionScoringContext(),
  }) {
    final reasons = <DecisionReasonCode>[];
    final notes = <String>[];
    final subscriptionScore = _scorer.score(
      bucket,
      context: scoringContext,
    );
    notes.add(
      'ml:model=${subscriptionScore.modelVersion}'
      ';p=${subscriptionScore.subscriptionProbability.toStringAsFixed(3)}'
      ';review=${subscriptionScore.reviewPriorityScore.toStringAsFixed(3)}',
    );
    if (subscriptionScore.subscriptionProbability >= 0.8) {
      reasons.add(DecisionReasonCode.mlHighSubscriptionProbability);
    } else if (subscriptionScore.subscriptionProbability <= 0.45) {
      reasons.add(DecisionReasonCode.mlLowSubscriptionProbability);
    }
    if (subscriptionScore.reviewPriorityScore >= 0.55) {
      reasons.add(DecisionReasonCode.mlReviewPriorityElevated);
    }
    notes.addAll(
      subscriptionScore.contributingSignals
          .map((signal) => 'ml:signal=$signal'),
    );

    final hasPaidEvidence = bucket.billedCount > 0;
    final hasBundleEvidence = bucket.bundleCount > 0;
    final hasSetupEvidence =
        bucket.mandateCount > 0 || bucket.autopaySetupCount > 0;
    final hasMicroEvidence = bucket.microChargeCount > 0;
    final hasReviewSignals = bucket.weakRecurringHintCount > 0 ||
        bucket.unknownReviewCount > 0 ||
        bucket.promoCount > 0 ||
        bucket.cancellationHintCount > 0;
    final hasLifecycleReviewSignals =
        bucket.renewalHintCount > 0 || bucket.cancellationHintCount > 0;
    final hasContradictions = bucket.contradictions.isNotEmpty;

    if (bucket.ignoreNoiseCount > 0 &&
        !hasPaidEvidence &&
        !hasBundleEvidence &&
        !hasSetupEvidence &&
        !hasMicroEvidence &&
        !hasReviewSignals &&
        bucket.oneTimePaymentNoiseCount == 0) {
      reasons.add(DecisionReasonCode.ignoreSignalsObserved);
      return _snapshot(
        bucket,
        band: DecisionBand.ignored,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
      );
    }

    if (bucket.oneTimePaymentNoiseCount > 0 &&
        !hasPaidEvidence &&
        !hasBundleEvidence &&
        !hasSetupEvidence &&
        !hasMicroEvidence &&
        !hasReviewSignals) {
      reasons.add(DecisionReasonCode.oneTimeNoiseObserved);
      return _snapshot(
        bucket,
        band: DecisionBand.oneTimeOrNoise,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
      );
    }

    if (hasPaidEvidence) {
      reasons.add(DecisionReasonCode.paidEvidenceObserved);
      if (bucket.renewalHintCount > 0 ||
          bucket.intervalHintsInDays.isNotEmpty) {
        reasons.add(DecisionReasonCode.recurringRenewalObserved);
      }
      if (hasContradictions) {
        reasons.add(DecisionReasonCode.contradictionObserved);
        notes.addAll(bucket.contradictions);
      }
      if (bucket.promoCount > 0 &&
          bucket.billedCount == 1 &&
          bucket.renewalHintCount == 0 &&
          bucket.intervalHintsInDays.isEmpty) {
        reasons.add(DecisionReasonCode.likelyPaidNeedsMoreHistory);
        reasons.add(DecisionReasonCode.promoSignalsObserved);
        return _snapshot(
          bucket,
          band: DecisionBand.likelyPaid,
          reasons: reasons,
          notes: notes,
          subscriptionScore: subscriptionScore,
          bridgeTotalBilled: bucket.amountSeries.fold<double>(
            0,
            (total, amount) => total + amount,
          ),
        );
      }

      if (bucket.billedCount == 1 &&
          bucket.renewalHintCount == 0 &&
          bucket.intervalHintsInDays.isEmpty &&
          subscriptionScore.subscriptionProbability < 0.55) {
        reasons.add(DecisionReasonCode.likelyPaidNeedsMoreHistory);
        return _snapshot(
          bucket,
          band: DecisionBand.likelyPaid,
          reasons: reasons,
          notes: notes,
          subscriptionScore: subscriptionScore,
          bridgeTotalBilled: bucket.amountSeries.fold<double>(
            0,
            (total, amount) => total + amount,
          ),
        );
      }

      return _snapshot(
        bucket,
        band: DecisionBand.confirmedPaid,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
        bridgeTotalBilled: bucket.amountSeries.fold<double>(
          0,
          (total, amount) => total + amount,
        ),
      );
    }

    if (hasBundleEvidence) {
      reasons.add(DecisionReasonCode.bundledBenefitObserved);
      if (hasLifecycleReviewSignals &&
          (bucket.weakRecurringHintCount > 0 ||
              bucket.unknownReviewCount > 0)) {
        reasons.add(DecisionReasonCode.weakRecurringSignalsObserved);
        if (bucket.renewalHintCount > 0) {
          reasons.add(DecisionReasonCode.recurringRenewalObserved);
        }
        if (bucket.cancellationHintCount > 0) {
          reasons.add(DecisionReasonCode.cancellationSignalsObserved);
        }
        if (hasContradictions) {
          reasons.add(DecisionReasonCode.contradictionObserved);
          notes.addAll(bucket.contradictions);
        }
        return _snapshot(
          bucket,
          band: DecisionBand.needsReview,
          reasons: reasons,
          notes: notes,
          subscriptionScore: subscriptionScore,
        );
      }
      if (hasContradictions) {
        reasons.add(DecisionReasonCode.contradictionObserved);
        notes.addAll(bucket.contradictions);
      }
      return _snapshot(
        bucket,
        band: DecisionBand.includedWithPlan,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
      );
    }

    if (hasMicroEvidence) {
      reasons.add(DecisionReasonCode.microVerificationObserved);
      if (hasContradictions) {
        reasons.add(DecisionReasonCode.contradictionObserved);
        notes.addAll(bucket.contradictions);
      }
      return _snapshot(
        bucket,
        band: DecisionBand.verificationOnly,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
      );
    }

    if (hasSetupEvidence) {
      reasons.add(DecisionReasonCode.setupIntentObserved);
      if (hasContradictions) {
        reasons.add(DecisionReasonCode.contradictionObserved);
        notes.addAll(bucket.contradictions);
      }
      return _snapshot(
        bucket,
        band: DecisionBand.setupOnly,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
      );
    }

    if (hasReviewSignals) {
      if (bucket.weakRecurringHintCount > 0 || bucket.unknownReviewCount > 0) {
        reasons.add(DecisionReasonCode.weakRecurringSignalsObserved);
      }
      if (bucket.promoCount > 0) {
        reasons.add(DecisionReasonCode.promoSignalsObserved);
      }
      if (bucket.cancellationHintCount > 0) {
        reasons.add(DecisionReasonCode.cancellationSignalsObserved);
      }
      return _snapshot(
        bucket,
        band: DecisionBand.needsReview,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
      );
    }

    reasons.add(DecisionReasonCode.ignoreSignalsObserved);
    return _snapshot(
      bucket,
      band: DecisionBand.ignored,
      reasons: reasons,
      notes: notes,
      subscriptionScore: subscriptionScore,
    );
  }

  DecisionSnapshot _snapshot(
    ServiceEvidenceBucket bucket, {
    required DecisionBand band,
    required List<DecisionReasonCode> reasons,
    required List<String> notes,
    required SubscriptionScore subscriptionScore,
    double bridgeTotalBilled = 0,
  }) {
    return DecisionSnapshot(
      serviceKey: bucket.serviceKey,
      band: band,
      decidedAt: bucket.lastSeenAt,
      lastBilledAt: bucket.lastBilledAt,
      bridgeTotalBilled: bridgeTotalBilled,
      reasonCodes: reasons,
      notes: notes,
      evidenceTrail: bucket.evidenceTrail,
      sourceBucket: bucket,
      subscriptionScore: subscriptionScore,
    );
  }
}
