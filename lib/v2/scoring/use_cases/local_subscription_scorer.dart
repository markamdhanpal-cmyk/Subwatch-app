import '../../../domain/entities/service_evidence_bucket.dart';
import '../../../domain/enums/merchant_resolution_confidence.dart';
import '../../../domain/enums/service_evidence_source_kind.dart';
import '../contracts/subscription_scorer.dart';
import '../models/subscription_score.dart';
import '../models/subscription_scoring_context.dart';
import '../models/subscription_scoring_features.dart';
import '../models/subscription_scoring_model_artifact.dart';

class LocalSubscriptionScorer implements SubscriptionScorer {
  const LocalSubscriptionScorer({
    SubscriptionScoringModelArtifact modelArtifact = defaultModelArtifact,
  }) : _modelArtifact = modelArtifact;

  static const SubscriptionScoringModelArtifact defaultModelArtifact =
      SubscriptionScoringModelArtifact(
        modelVersion: 'subwatch_structured_local_v1',
        featureSchemaVersion: 1,
        intercept: -1.2,
        weights: <String, double>{
          'billedEvidence': 1.35,
          'renewalHint': 0.55,
          'mandateEvidence': -0.75,
          'autopaySetup': -0.55,
          'microCharge': -1.2,
          'bundleEvidence': -1.1,
          'promoEvidence': -0.35,
          'cancellationHint': -0.25,
          'weakRecurringHint': -0.35,
          'unknownReview': -0.4,
          'contradiction': -0.7,
          'sourceTrust': 0.45,
          'merchantConfidence': 0.8,
          'intervalStability': 0.7,
          'amountStability': 0.65,
          'userConfirmed': 0.25,
          'userRejected': -0.65,
          'userMarkedBenefit': -0.45,
        },
      );

  final SubscriptionScoringModelArtifact _modelArtifact;

  @override
  SubscriptionScore score(
    ServiceEvidenceBucket bucket, {
    SubscriptionScoringContext context = const SubscriptionScoringContext(),
  }) {
    final features = _featuresFor(bucket, context: context);
    final weightedSum = _modelArtifact.intercept +
        _weight('billedEvidence') * _cap(features.billedEvidenceCount, 3) +
        _weight('renewalHint') * _cap(features.renewalHintCount, 3) +
        _weight('mandateEvidence') * _cap(features.mandateEvidenceCount, 2) +
        _weight('autopaySetup') * _cap(features.autopaySetupCount, 2) +
        _weight('microCharge') * _cap(features.microChargeCount, 2) +
        _weight('bundleEvidence') * _cap(features.bundleEvidenceCount, 2) +
        _weight('promoEvidence') * _cap(features.promoEvidenceCount, 3) +
        _weight('cancellationHint') * _cap(features.cancellationHintCount, 2) +
        _weight('weakRecurringHint') * _cap(features.weakRecurringHintCount, 2) +
        _weight('unknownReview') * _cap(features.unknownReviewCount, 2) +
        _weight('contradiction') * _cap(features.contradictionCount, 3) +
        _weight('sourceTrust') * features.sourceTrustScore +
        _weight('merchantConfidence') * features.merchantConfidenceScore +
        _weight('intervalStability') * features.intervalStabilityScore +
        _weight('amountStability') * features.amountStabilityScore +
        _weight('userConfirmed') * _cap(features.userConfirmedCount, 3) +
        _weight('userRejected') * _cap(features.userRejectedCount, 3) +
        _weight('userMarkedBenefit') * _cap(features.userMarkedBenefitCount, 3);
    final subscriptionProbability = _sigmoid(weightedSum);
    final reviewPriorityScore = _reviewPriorityScore(
      features: features,
      probability: subscriptionProbability,
    );

    return SubscriptionScore(
      modelVersion: _modelArtifact.modelVersion,
      featureSchemaVersion: _modelArtifact.featureSchemaVersion,
      subscriptionProbability: subscriptionProbability,
      reviewPriorityScore: reviewPriorityScore,
      contributingSignals: _contributingSignals(features),
    );
  }

  SubscriptionScoringFeatures _featuresFor(
    ServiceEvidenceBucket bucket, {
    required SubscriptionScoringContext context,
  }) {
    return SubscriptionScoringFeatures(
      featureSchemaVersion: _modelArtifact.featureSchemaVersion,
      billedEvidenceCount: bucket.billedCount,
      renewalHintCount: bucket.renewalHintCount,
      mandateEvidenceCount: bucket.mandateCount,
      autopaySetupCount: bucket.autopaySetupCount,
      microChargeCount: bucket.microChargeCount,
      bundleEvidenceCount: bucket.bundleCount,
      promoEvidenceCount: bucket.promoCount,
      cancellationHintCount: bucket.cancellationHintCount,
      weakRecurringHintCount: bucket.weakRecurringHintCount,
      unknownReviewCount: bucket.unknownReviewCount,
      contradictionCount: bucket.contradictions.length,
      sourceTrustScore: _sourceTrustScore(bucket.sourceKindsSeen),
      merchantConfidenceScore: _merchantConfidenceScore(bucket),
      intervalStabilityScore: _intervalStabilityScore(bucket),
      amountStabilityScore: _amountStabilityScore(bucket),
      userConfirmedCount: context.userConfirmedCount,
      userRejectedCount: context.userRejectedCount,
      userMarkedBenefitCount: context.userMarkedBenefitCount,
    );
  }

  double _sourceTrustScore(List<ServiceEvidenceSourceKind> sourceKinds) {
    if (sourceKinds.isEmpty) {
      return 0;
    }

    var best = 0.0;
    for (final sourceKind in sourceKinds) {
      final candidate = switch (sourceKind) {
        ServiceEvidenceSourceKind.deviceSmsInbox => 0.8,
        ServiceEvidenceSourceKind.deviceMmsInbox => 0.72,
        ServiceEvidenceSourceKind.deviceRcsInbox => 0.74,
        ServiceEvidenceSourceKind.emailReceiptImport => 0.6,
        ServiceEvidenceSourceKind.googlePlayRecord => 0.7,
        ServiceEvidenceSourceKind.appleAppStoreRecord => 0.68,
        ServiceEvidenceSourceKind.bankConnectorSync => 0.76,
        ServiceEvidenceSourceKind.sampleSeedData => 0.25,
        ServiceEvidenceSourceKind.manualEntry => 0.55,
        ServiceEvidenceSourceKind.manualReceiptEntry => 0.5,
        ServiceEvidenceSourceKind.csvImport => 0.52,
        ServiceEvidenceSourceKind.legacyMessageRecordBridge => 0.45,
      };
      if (candidate > best) {
        best = candidate;
      }
    }

    return best;
  }

  double _merchantConfidenceScore(ServiceEvidenceBucket bucket) {
    var best = MerchantResolutionConfidence.none;
    for (final note in bucket.evidenceTrail.notes) {
      if (!note.startsWith('merchant_resolution:')) {
        continue;
      }
      final parts = note.split(':');
      if (parts.length < 3) {
        continue;
      }
      final confidenceName = parts[2];
      final confidence = MerchantResolutionConfidence.values.where(
        (value) => value.name == confidenceName,
      );
      if (confidence.isEmpty) {
        continue;
      }
      if (confidence.first.index > best.index) {
        best = confidence.first;
      }
    }

    return switch (best) {
      MerchantResolutionConfidence.high => 1,
      MerchantResolutionConfidence.medium => 0.72,
      MerchantResolutionConfidence.low => 0.45,
      MerchantResolutionConfidence.none => 0,
    };
  }

  double _intervalStabilityScore(ServiceEvidenceBucket bucket) {
    final intervals = bucket.intervalHintsInDays;
    if (intervals.isEmpty) {
      return 0;
    }

    final stableIntervals = intervals.where((days) => days >= 27 && days <= 35).length;
    if (stableIntervals == intervals.length) {
      return 1;
    }

    final stableRatio = stableIntervals / intervals.length;
    return stableRatio >= 0.5 ? 0.65 : 0.25;
  }

  double _amountStabilityScore(ServiceEvidenceBucket bucket) {
    final amounts = bucket.amountSeries;
    if (amounts.isEmpty) {
      return 0;
    }
    if (amounts.length == 1) {
      return bucket.billedCount > 0 ? 0.45 : 0.2;
    }

    final minAmount = amounts.reduce(
      (left, right) => left < right ? left : right,
    );
    final maxAmount = amounts.reduce(
      (left, right) => left > right ? left : right,
    );
    if (minAmount <= 0) {
      return 0;
    }

    final varianceRatio = (maxAmount - minAmount) / minAmount;
    if (varianceRatio <= 0.05) {
      return 1;
    }
    if (varianceRatio <= 0.15) {
      return 0.72;
    }
    return 0.3;
  }

  double _reviewPriorityScore({
    required SubscriptionScoringFeatures features,
    required double probability,
  }) {
    var score = 0.15;
    score += _cap(features.weakRecurringHintCount, 2) * 0.12;
    score += _cap(features.unknownReviewCount, 2) * 0.14;
    score += _cap(features.contradictionCount, 3) * 0.12;
    score += _cap(features.promoEvidenceCount, 3) * 0.06;
    score += _cap(features.cancellationHintCount, 2) * 0.08;
    score += _cap(features.userRejectedCount, 2) * 0.08;
    if (features.mandateEvidenceCount > 0 ||
        features.autopaySetupCount > 0 ||
        features.microChargeCount > 0 ||
        features.bundleEvidenceCount > 0) {
      score += 0.18;
    }
    if (probability >= 0.25 && probability <= 0.8) {
      score += 0.2;
    }

    if (score < 0) {
      return 0;
    }
    if (score > 1) {
      return 1;
    }
    return score;
  }

  List<String> _contributingSignals(SubscriptionScoringFeatures features) {
    final signals = <String>[];
    if (features.billedEvidenceCount > 0) {
      signals.add('billed_evidence');
    }
    if (features.renewalHintCount > 0) {
      signals.add('renewal_hints');
    }
    if (features.intervalStabilityScore >= 0.65) {
      signals.add('stable_interval_pattern');
    }
    if (features.amountStabilityScore >= 0.65) {
      signals.add('stable_amount_pattern');
    }
    if (features.merchantConfidenceScore >= 0.72) {
      signals.add('high_confidence_merchant_resolution');
    }
    if (features.mandateEvidenceCount > 0 || features.autopaySetupCount > 0) {
      signals.add('setup_only_evidence');
    }
    if (features.microChargeCount > 0) {
      signals.add('micro_charge_guardrail');
    }
    if (features.bundleEvidenceCount > 0) {
      signals.add('bundle_guardrail');
    }
    if (features.contradictionCount > 0) {
      signals.add('contradictions_present');
    }
    if (features.userConfirmedCount > 0) {
      signals.add('user_confirmed_history');
    }
    if (features.userRejectedCount > 0) {
      signals.add('user_rejected_history');
    }
    return signals;
  }

  double _weight(String key) => _modelArtifact.weights[key] ?? 0;

  double _cap(int value, int max) {
    if (max <= 0) {
      return 0;
    }
    final bounded = value > max ? max : value;
    return bounded / max;
  }

  double _sigmoid(double value) {
    final exponent = value < 0 ? -value : value;
    final denominator = 1 + _expApprox(exponent);
    final base = 1 / denominator;
    return value >= 0 ? 1 - base : base;
  }

  double _expApprox(double value) {
    var sum = 1.0;
    var term = 1.0;
    for (var index = 1; index <= 12; index += 1) {
      term *= value / index;
      sum += term;
    }
    return sum;
  }
}

