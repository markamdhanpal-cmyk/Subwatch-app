import '../../../domain/entities/service_evidence_bucket.dart';
import '../../../domain/enums/subscription_evidence_kind.dart';
import '../../scoring/contracts/subscription_scorer.dart';
import '../../scoring/models/subscription_score.dart';
import '../../scoring/models/subscription_scoring_context.dart';
import '../../scoring/use_cases/rule_based_subscription_scorer.dart';
import '../enums/decision_band.dart';
import '../enums/decision_reason_code.dart';
import '../models/decision_snapshot.dart';
import 'build_service_evidence_profile_use_case.dart';

class DecisionEngineV2UseCase {
  const DecisionEngineV2UseCase({
    SubscriptionScorer scorer = const RuleBasedSubscriptionScorer(),
    BuildServiceEvidenceProfileUseCase evidenceProfileBuilder =
        const BuildServiceEvidenceProfileUseCase(),
  })  : _scorer = scorer,
        _evidenceProfileBuilder = evidenceProfileBuilder;

  final SubscriptionScorer _scorer;
  final BuildServiceEvidenceProfileUseCase _evidenceProfileBuilder;

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
    final profile = _evidenceProfileBuilder.execute(bucket);
    final reasons = <DecisionReasonCode>[];
    final notes = <String>[
      'decision:model=deterministic_service_level_v3',
    ];
    final subscriptionScore = _scorer.score(
      bucket,
      context: scoringContext,
    );

    final hasPaidEvidence = profile.has(SubscriptionEvidenceKind.paidCharge);
    final hasBundleEvidence =
        profile.has(SubscriptionEvidenceKind.bundleBenefit);
    final hasSetupEvidence = profile.has(SubscriptionEvidenceKind.mandateSetup);
    final hasMicroEvidence =
        profile.has(SubscriptionEvidenceKind.microVerification);
    final hasRenewalHints = profile.has(SubscriptionEvidenceKind.renewalHint);
    final hasCancellationHints =
        profile.has(SubscriptionEvidenceKind.cancellationHint);
    final hasPromoNoise = profile.has(SubscriptionEvidenceKind.promoNoise);
    final hasOtpNoise = profile.has(SubscriptionEvidenceKind.otpNoise);
    final hasOneTimeNoise = profile.has(SubscriptionEvidenceKind.upiOneTime);
    final hasTelecomRechargeNoise =
        profile.has(SubscriptionEvidenceKind.telecomRechargeNoise);
    final hasWeakReviewHints =
        bucket.weakRecurringHintCount > 0 || bucket.unknownReviewCount > 0;
    final hasExplicitEndedEvidence = bucket.endedLifecycleCount > 0;
    final hasContradictions = bucket.contradictions.isNotEmpty;

    if (hasExplicitEndedEvidence) {
      reasons.add(DecisionReasonCode.cancellationSignalsObserved);
      if (hasContradictions) {
        reasons.add(DecisionReasonCode.contradictionObserved);
        notes.addAll(bucket.contradictions);
      }
      return _snapshot(
        bucket,
        band: DecisionBand.ended,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
      );
    }

    if (hasPaidEvidence) {
      reasons.add(DecisionReasonCode.paidEvidenceObserved);
      if (hasRenewalHints || bucket.intervalHintsInDays.isNotEmpty) {
        reasons.add(DecisionReasonCode.recurringRenewalObserved);
      }
      if (hasContradictions) {
        reasons.add(DecisionReasonCode.contradictionObserved);
        notes.addAll(bucket.contradictions);
      }

      final hasSingleChargeOnly = bucket.billedCount == 1 &&
          !hasRenewalHints &&
          bucket.intervalHintsInDays.isEmpty;
      if (hasSingleChargeOnly &&
          !_isHighConfidenceSingleCharge(bucket,
              hasPromoNoise: hasPromoNoise)) {
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

    if (hasWeakReviewHints || hasRenewalHints || hasCancellationHints) {
      reasons.add(DecisionReasonCode.weakRecurringSignalsObserved);
      if (hasRenewalHints) {
        reasons.add(DecisionReasonCode.recurringRenewalObserved);
      }
      if (hasCancellationHints) {
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

    if (hasOneTimeNoise) {
      reasons.add(DecisionReasonCode.oneTimeNoiseObserved);
      return _snapshot(
        bucket,
        band: DecisionBand.oneTimeOrNoise,
        reasons: reasons,
        notes: notes,
        subscriptionScore: subscriptionScore,
      );
    }

    if (hasPromoNoise ||
        hasOtpNoise ||
        hasTelecomRechargeNoise ||
        bucket.ignoreNoiseCount > 0) {
      reasons.add(DecisionReasonCode.ignoreSignalsObserved);
      if (hasPromoNoise) {
        reasons.add(DecisionReasonCode.promoSignalsObserved);
      }
      return _snapshot(
        bucket,
        band: DecisionBand.ignored,
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

  bool _isHighConfidenceSingleCharge(
    ServiceEvidenceBucket bucket, {
    required bool hasPromoNoise,
  }) {
    final hasMerchantResolutionConfidence = bucket.evidenceTrail.notes.any(
      (note) =>
          note.startsWith('merchant_resolution:') &&
          (note.contains(':high:') || note.contains(':medium:')),
    );
    if (!hasMerchantResolutionConfidence) {
      return false;
    }

    final hasAnnualCadenceTerm = bucket.evidenceTrail.notes.any((note) {
      final lower = note.toLowerCase();
      return lower.contains('annual') ||
          lower.contains('yearly') ||
          lower.contains('12-month');
    });

    final serviceKeyValue = bucket.serviceKey.value.toUpperCase();
    final looksLikeStoreRail = serviceKeyValue.contains('GOOGLE_PLAY') ||
        serviceKeyValue.contains('APPLE_APP_STORE') ||
        serviceKeyValue.contains('APP_STORE') ||
        serviceKeyValue.contains('ITUNES');
    if (looksLikeStoreRail) {
      if (!hasAnnualCadenceTerm) {
        return false;
      }
      final hasHighConfidenceMerchantResolution = bucket.evidenceTrail.notes.any(
        (note) =>
            note.startsWith('merchant_resolution:') &&
            note.contains(':high:'),
      );
      if (!hasHighConfidenceMerchantResolution) {
        return false;
      }
    }

    if (hasPromoNoise && !hasAnnualCadenceTerm) {
      return false;
    }

    return true;
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
