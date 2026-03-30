import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_evidence_bucket.dart';
import 'package:sub_killer/domain/enums/service_evidence_source_kind.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';
import 'package:sub_killer/v2/decision/enums/decision_band.dart';
import 'package:sub_killer/v2/decision/enums/decision_reason_code.dart';
import 'package:sub_killer/v2/decision/use_cases/decision_engine_v2_use_case.dart';
import 'package:sub_killer/v2/scoring/contracts/subscription_scorer.dart';
import 'package:sub_killer/v2/scoring/models/subscription_score.dart';
import 'package:sub_killer/v2/scoring/models/subscription_scoring_context.dart';

void main() {
  group('DecisionEngineV2UseCase', () {
    const useCase = DecisionEngineV2UseCase();

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
      int weakRecurringHintCount = 0,
      int unknownReviewCount = 0,
      int oneTimePaymentNoiseCount = 0,
      int ignoreNoiseCount = 0,
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
        weakRecurringHintCount: weakRecurringHintCount,
        unknownReviewCount: unknownReviewCount,
        oneTimePaymentNoiseCount: oneTimePaymentNoiseCount,
        ignoreNoiseCount: ignoreNoiseCount,
        amountSeries: amountSeries,
        intervalHintsInDays: intervalHintsInDays,
        contradictions: contradictions,
        evidenceTrail: EvidenceTrail(notes: evidenceNotes),
      );
    }

    test('confirmed paid bucket stays confirmed paid', () {
      final snapshot = useCase.decide(
        bucket(
          key: 'NETFLIX',
          billedCount: 2,
          renewalHintCount: 2,
          amountSeries: const <double>[499, 499],
          intervalHintsInDays: const <int>[31],
          evidenceNotes: const <String>[
            'merchant_resolution:exactAlias:high:netflix'
          ],
        ),
      );

      expect(snapshot.band, DecisionBand.confirmedPaid);
      expect(snapshot.subscriptionScore.modelVersion,
          'subwatch_structured_local_v1');
      expect(
          snapshot.subscriptionScore.subscriptionProbability, greaterThan(0.7));
    });

    test('promo-tainted single billed signal becomes likely paid', () {
      final snapshot = useCase.decide(
        bucket(
          key: 'MYSTERY_PLUS',
          billedCount: 1,
          promoCount: 1,
          amountSeries: const <double>[199],
        ),
      );

      expect(snapshot.band, DecisionBand.likelyPaid);
    });

    test('low-score single billed signal is downgraded to likely paid', () {
      final snapshot = const DecisionEngineV2UseCase(
        scorer: _StubSubscriptionScorer(
          probability: 0.52,
          reviewPriority: 0.44,
        ),
      ).decide(
        bucket(
          key: 'MUSIC_PLUS',
          billedCount: 1,
          amountSeries: const <double>[149],
        ),
      );

      expect(snapshot.band, DecisionBand.likelyPaid);
    });

    test('setup-only bucket stays setup only even with high ml score', () {
      final snapshot = const DecisionEngineV2UseCase(
        scorer: _StubSubscriptionScorer(
          probability: 0.97,
          reviewPriority: 0.61,
        ),
      ).decide(
        bucket(
          key: 'JIOHOTSTAR',
          mandateCount: 1,
        ),
      );

      expect(snapshot.band, DecisionBand.setupOnly);
    });

    test('micro bucket stays verification only', () {
      final snapshot = useCase.decide(
        bucket(
          key: 'CRUNCHYROLL',
          microChargeCount: 1,
        ),
      );

      expect(snapshot.band, DecisionBand.verificationOnly);
    });

    test('bundle-only bucket stays included with plan', () {
      final snapshot = useCase.decide(
        bucket(
          key: 'GOOGLE_GEMINI_PRO',
          bundleCount: 1,
        ),
      );

      expect(snapshot.band, DecisionBand.includedWithPlan);
    });

    test('bundle evidence with renewal-risk review signals stays in review',
        () {
      final snapshot = useCase.decide(
        bucket(
          key: 'JIOHOTSTAR',
          bundleCount: 3,
          renewalHintCount: 1,
          cancellationHintCount: 1,
          weakRecurringHintCount: 1,
          unknownReviewCount: 1,
        ),
      );

      expect(snapshot.band, DecisionBand.needsReview);
      expect(
        snapshot.reasonCodes,
        containsAll(<DecisionReasonCode>[
          DecisionReasonCode.bundledBenefitObserved,
          DecisionReasonCode.weakRecurringSignalsObserved,
          DecisionReasonCode.recurringRenewalObserved,
          DecisionReasonCode.cancellationSignalsObserved,
        ]),
      );
    });

    test('weak recurring bucket stays needs review with low certainty', () {
      final snapshot = useCase.decide(
        bucket(
          key: 'GOOGLE_PLAY',
          weakRecurringHintCount: 1,
          unknownReviewCount: 1,
        ),
      );

      expect(snapshot.band, DecisionBand.needsReview);
      expect(
          snapshot.subscriptionScore.subscriptionProbability, lessThan(0.35));
      expect(snapshot.subscriptionScore.reviewPriorityScore, greaterThan(0.25));
    });

    test('user rejection history lowers advisory probability', () {
      final snapshot = useCase.decide(
        bucket(
          key: 'MYSTERY_REVIEW',
          weakRecurringHintCount: 1,
          unknownReviewCount: 1,
          evidenceNotes: const <String>[
            'merchant_resolution:tokenAlias:medium:mystery'
          ],
        ),
        scoringContext: const SubscriptionScoringContext(userRejectedCount: 2),
      );

      expect(
          snapshot.subscriptionScore.subscriptionProbability, lessThan(0.55));
    });

    test('one-time noise bucket stays one time or noise', () {
      final snapshot = useCase.decide(
        bucket(
          key: 'SHOPPING',
          oneTimePaymentNoiseCount: 1,
        ),
      );

      expect(snapshot.band, DecisionBand.oneTimeOrNoise);
    });

    test('ignore-only bucket stays ignored', () {
      final snapshot = useCase.decide(
        bucket(
          key: 'IGNORE_ME',
          ignoreNoiseCount: 1,
        ),
      );

      expect(snapshot.band, DecisionBand.ignored);
    });
  });
}

class _StubSubscriptionScorer implements SubscriptionScorer {
  const _StubSubscriptionScorer({
    required this.probability,
    required this.reviewPriority,
  });

  final double probability;
  final double reviewPriority;

  @override
  SubscriptionScore score(
    ServiceEvidenceBucket bucket, {
    SubscriptionScoringContext context = const SubscriptionScoringContext(),
  }) {
    return SubscriptionScore(
      modelVersion: 'stub-model-v1',
      featureSchemaVersion: 1,
      subscriptionProbability: probability,
      reviewPriorityScore: reviewPriority,
      contributingSignals: const <String>['stubbed_score'],
    );
  }
}
