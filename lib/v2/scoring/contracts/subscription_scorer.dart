import '../../../domain/entities/service_evidence_bucket.dart';
import '../models/subscription_score.dart';
import '../models/subscription_scoring_context.dart';

abstract interface class SubscriptionScorer {
  SubscriptionScore score(
    ServiceEvidenceBucket bucket, {
    SubscriptionScoringContext context = const SubscriptionScoringContext(),
  });
}
