import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_evidence_bucket.dart';
import 'package:sub_killer/domain/enums/service_evidence_source_kind.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';
import 'package:sub_killer/v2/scoring/models/subscription_scoring_context.dart';
import 'package:sub_killer/v2/scoring/use_cases/local_subscription_scorer.dart';

void main() {
  group('LocalSubscriptionScorer', () {
    const scorer = LocalSubscriptionScorer();

    ServiceEvidenceBucket bucket({
      required String key,
      int billedCount = 0,
      int renewalHintCount = 0,
      int mandateCount = 0,
      int autopaySetupCount = 0,
      int microChargeCount = 0,
      int bundleCount = 0,
      int promoCount = 0,
      int cancellationHintCount = 0,
      List<double> amountSeries = const <double>[],
      List<int> intervalHintsInDays = const <int>[],
      List<String> contradictions = const <String>[],
      List<String> evidenceNotes = const <String>[],
    }) {
      return ServiceEvidenceBucket(
        serviceKey: ServiceKey(key),
        firstSeenAt: DateTime(2026, 3, 1, 9),
        lastSeenAt: DateTime(2026, 3, 2, 9),
        lastBilledAt: billedCount > 0 ? DateTime(2026, 3, 2, 9) : null,
        sourceKindsSeen: const <ServiceEvidenceSourceKind>[
          ServiceEvidenceSourceKind.deviceSmsInbox,
        ],
        billedCount: billedCount,
        renewalHintCount: renewalHintCount,
        mandateCount: mandateCount,
        autopaySetupCount: autopaySetupCount,
        microChargeCount: microChargeCount,
        bundleCount: bundleCount,
        promoCount: promoCount,
        cancellationHintCount: cancellationHintCount,
        amountSeries: amountSeries,
        intervalHintsInDays: intervalHintsInDays,
        contradictions: contradictions,
        evidenceTrail: EvidenceTrail(notes: evidenceNotes),
      );
    }

    test('scores stable recurring paid evidence higher than setup-only evidence', () {
      final paidScore = scorer.score(
        bucket(
          key: 'NETFLIX',
          billedCount: 2,
          renewalHintCount: 2,
          amountSeries: const <double>[499, 499],
          intervalHintsInDays: const <int>[31],
          evidenceNotes: const <String>[
            'merchant_resolution:exactAlias:high:netflix',
          ],
        ),
      );
      final setupScore = scorer.score(
        bucket(
          key: 'JIOHOTSTAR',
          mandateCount: 1,
          evidenceNotes: const <String>[
            'merchant_resolution:exactAlias:high:jiohotstar',
          ],
        ),
      );

      expect(paidScore.modelVersion, 'subwatch_structured_local_v1');
      expect(paidScore.featureSchemaVersion, 1);
      expect(
        paidScore.subscriptionProbability,
        greaterThan(setupScore.subscriptionProbability),
      );
    });

    test('bundle and micro guardrails lower the subscription probability', () {
      final bundleScore = scorer.score(
        bucket(
          key: 'GOOGLE_GEMINI_PRO',
          bundleCount: 1,
          evidenceNotes: const <String>[
            'merchant_resolution:exactAlias:high:google gemini pro',
          ],
        ),
      );
      final microScore = scorer.score(
        bucket(
          key: 'CRUNCHYROLL',
          microChargeCount: 1,
          evidenceNotes: const <String>[
            'merchant_resolution:exactAlias:high:crunchyroll',
          ],
        ),
      );

      expect(bundleScore.subscriptionProbability, lessThan(0.5));
      expect(microScore.subscriptionProbability, lessThan(0.5));
    });

    test('user rejection history lowers advisory score and raises review priority', () {
      final neutral = scorer.score(
        bucket(
          key: 'MYSTERY_PLUS',
          billedCount: 1,
          amountSeries: const <double>[149],
          evidenceNotes: const <String>[
            'merchant_resolution:tokenAlias:medium:mystery plus',
          ],
        ),
      );
      final rejected = scorer.score(
        bucket(
          key: 'MYSTERY_PLUS',
          billedCount: 1,
          amountSeries: const <double>[149],
          evidenceNotes: const <String>[
            'merchant_resolution:tokenAlias:medium:mystery plus',
          ],
        ),
        context: const SubscriptionScoringContext(userRejectedCount: 2),
      );

      expect(
        rejected.subscriptionProbability,
        lessThan(neutral.subscriptionProbability),
      );
      expect(rejected.reviewPriorityScore, greaterThan(neutral.reviewPriorityScore));
    });

    test('weak recurring signals stay low certainty but get elevated review priority', () {
      final score = scorer.score(
        bucket(
          key: 'GOOGLE_PLAY',
          evidenceNotes: const <String>[
            'merchant_resolution:tokenAlias:medium:google play',
          ],
        ).copyWith(
          weakRecurringHintCount: 1,
          unknownReviewCount: 1,
        ),
      );

      expect(score.subscriptionProbability, lessThan(0.35));
      expect(score.reviewPriorityScore, greaterThan(0.3));
    });
  });
}
