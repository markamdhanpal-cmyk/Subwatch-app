import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/service_evidence_bucket.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/v2/scoring/use_cases/local_subscription_scorer.dart';

void main() {
  group('Cadence Model Upgrade - Scorer Regression', () {
    const scorer = LocalSubscriptionScorer();

    ServiceEvidenceBucket createBucketWithIntervals(List<int> intervals) {
      return ServiceEvidenceBucket(
        serviceKey: const ServiceKey('TEST'),
        firstSeenAt: DateTime(2023, 1, 1),
        lastSeenAt: DateTime(2024, 1, 1),
        sourceKindsSeen: const [],
        evidenceTrail: EvidenceTrail.empty(),
        intervalHintsInDays: intervals,
        billedCount: intervals.length + 1,
      );
    }

    test('Monthly intervals (30-31 days) are scored as stable', () {
      final bucket = createBucketWithIntervals([30, 31, 30]);
      final score = scorer.score(bucket);
      
      expect(score.contributingSignals, contains('stable_interval_pattern'));
      expect(score.subscriptionProbability, greaterThan(0.5));
    });

    test('Quarterly intervals (90-92 days) are scored as stable', () {
      final bucket = createBucketWithIntervals([90, 91]);
      final score = scorer.score(bucket);
      
      expect(score.contributingSignals, contains('stable_interval_pattern'));
      expect(score.subscriptionProbability, greaterThan(0.5));
    });

    test('Annual intervals (365 days) are scored as stable', () {
      final bucket = createBucketWithIntervals([365]);
      final score = scorer.score(bucket);
      
      expect(score.contributingSignals, contains('stable_interval_pattern'));
      expect(score.subscriptionProbability, greaterThan(0.5));
    });

    test('Ambiguous/Irregular intervals (e.g. 45 days) are NOT scored as stable', () {
      final bucket = createBucketWithIntervals([45, 45]);
      final score = scorer.score(bucket);
      
      expect(score.contributingSignals, isNot(contains('stable_interval_pattern')));
    });

    test('Mixed intervals favors dominant cadence (mostly monthly)', () {
      final bucket = createBucketWithIntervals([30, 31, 90]);
      final score = scorer.score(bucket);
      
      // 2/3 are monthly => stableRatio 0.66 => stable_interval_pattern
      expect(score.contributingSignals, contains('stable_interval_pattern'));
    });

    test('Mixed intervals without majority cadence are NOT stable', () {
      final bucket = createBucketWithIntervals([30, 90, 365]);
      final score = scorer.score(bucket);
      
      // No majority => each is 1/3 => stableRatio < 0.5
      expect(score.contributingSignals, isNot(contains('stable_interval_pattern')));
    });
  });
}
