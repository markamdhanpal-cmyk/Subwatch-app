import '../../../domain/entities/service_evidence_bucket.dart';
import '../contracts/subscription_scorer.dart';
import '../models/subscription_score.dart';
import '../models/subscription_scoring_context.dart';

class RuleBasedSubscriptionScorer implements SubscriptionScorer {
  const RuleBasedSubscriptionScorer();

  @override
  SubscriptionScore score(
    ServiceEvidenceBucket bucket, {
    SubscriptionScoringContext context = const SubscriptionScoringContext(),
  }) {
    var probability = _baseProbability(bucket);
    probability += context.userConfirmedCount * 0.03;
    probability -= context.userRejectedCount * 0.06;
    probability -= context.userMarkedBenefitCount * 0.02;
    probability = _clamp(probability);

    final reviewPriority = _reviewPriority(bucket);

    return SubscriptionScore(
      modelVersion: 'deterministic_rules_v1',
      featureSchemaVersion: 1,
      subscriptionProbability: probability,
      reviewPriorityScore: reviewPriority,
      contributingSignals: _signals(bucket),
    );
  }

  double _baseProbability(ServiceEvidenceBucket bucket) {
    if (bucket.billedCount > 1) {
      return 0.93;
    }

    if (bucket.billedCount == 1) {
      return 0.78;
    }

    if (bucket.bundleCount > 0) {
      return 0.22;
    }

    if (bucket.mandateCount > 0 || bucket.autopaySetupCount > 0) {
      return 0.18;
    }

    if (bucket.microChargeCount > 0) {
      return 0.08;
    }

    if (bucket.weakRecurringHintCount > 0 || bucket.unknownReviewCount > 0) {
      return 0.28;
    }

    if (bucket.cancellationHintCount > 0) {
      return 0.24;
    }

    if (bucket.oneTimePaymentNoiseCount > 0 || bucket.ignoreNoiseCount > 0) {
      return 0.01;
    }

    return 0.02;
  }

  double _reviewPriority(ServiceEvidenceBucket bucket) {
    var priority = 0.05;
    if (bucket.weakRecurringHintCount > 0 || bucket.unknownReviewCount > 0) {
      priority += 0.3;
    }
    if (bucket.mandateCount > 0 ||
        bucket.autopaySetupCount > 0 ||
        bucket.microChargeCount > 0) {
      priority += 0.22;
    }
    if (bucket.contradictions.isNotEmpty) {
      priority += 0.24;
    }
    if (bucket.cancellationHintCount > 0) {
      priority += 0.14;
    }
    if (bucket.promoCount > 0) {
      priority += 0.08;
    }

    return _clamp(priority);
  }

  List<String> _signals(ServiceEvidenceBucket bucket) {
    final signals = <String>[];
    if (bucket.billedCount > 0) {
      signals.add('paid_charge');
    }
    if (bucket.bundleCount > 0) {
      signals.add('bundle_benefit');
    }
    if (bucket.mandateCount > 0 || bucket.autopaySetupCount > 0) {
      signals.add('mandate_setup');
    }
    if (bucket.microChargeCount > 0) {
      signals.add('micro_verification');
    }
    if (bucket.weakRecurringHintCount > 0 || bucket.unknownReviewCount > 0) {
      signals.add('possible_unconfirmed');
    }
    if (bucket.oneTimePaymentNoiseCount > 0 || bucket.ignoreNoiseCount > 0) {
      signals.add('hidden_noise');
    }
    return signals;
  }

  double _clamp(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }
}
