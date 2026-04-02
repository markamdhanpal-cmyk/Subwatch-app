import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/service_evidence_aggregate.dart';
import 'package:sub_killer/domain/entities/subscription_evidence.dart';
import 'package:sub_killer/domain/enums/service_decision_state.dart';
import 'package:sub_killer/domain/enums/subscription_evidence_kind.dart';
import 'package:sub_killer/domain/services/subscription_decision_engine_v3.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('SubscriptionDecisionEngineV3', () {
    const engine = SubscriptionDecisionEngineV3();

    ServiceEvidenceAggregate aggregate({
      required String serviceKey,
      List<SubscriptionEvidence> evidences = const <SubscriptionEvidence>[],
      List<int> intervals = const <int>[],
      List<double> amounts = const <double>[],
      bool hasStrongMerchantMatch = true,
      bool hasEndedLifecycleEvidence = false,
    }) {
      return ServiceEvidenceAggregate(
        serviceKey: ServiceKey(serviceKey),
        evidences: evidences,
        intervalHintsInDays: intervals,
        amountSeries: amounts,
        hasStrongMerchantMatch: hasStrongMerchantMatch,
        hasEndedLifecycleEvidence: hasEndedLifecycleEvidence,
      );
    }

    SubscriptionEvidence evidence(SubscriptionEvidenceKind kind, int count) {
      return SubscriptionEvidence.aggregate(kind: kind, count: count);
    }

    test('confirmed paid requires paid evidence and strong merchant match', () {
      final result = engine.decide(
        aggregate(
          serviceKey: 'NETFLIX',
          evidences: <SubscriptionEvidence>[
            evidence(SubscriptionEvidenceKind.paidCharge, 2),
          ],
          intervals: const <int>[30],
        ),
      );

      expect(result, ServiceDecisionState.confirmedPaid);
    });

    test('bundle only becomes included with plan', () {
      final result = engine.decide(
        aggregate(
          serviceKey: 'WYNK',
          evidences: <SubscriptionEvidence>[
            evidence(SubscriptionEvidenceKind.bundleBenefit, 1),
          ],
        ),
      );

      expect(result, ServiceDecisionState.includedWithPlan);
    });

    test('setup-only evidence stays setup only', () {
      final result = engine.decide(
        aggregate(
          serviceKey: 'YOUTUBE_PREMIUM',
          evidences: <SubscriptionEvidence>[
            evidence(SubscriptionEvidenceKind.mandateSetup, 1),
          ],
        ),
      );

      expect(result, ServiceDecisionState.setupOnly);
    });

    test('ended lifecycle evidence wins over ambiguous signals', () {
      final result = engine.decide(
        aggregate(
          serviceKey: 'NETFLIX',
          evidences: <SubscriptionEvidence>[
            evidence(SubscriptionEvidenceKind.cancellationHint, 1),
          ],
          hasEndedLifecycleEvidence: true,
        ),
      );

      expect(result, ServiceDecisionState.ended);
    });
    test('contradictory paid and bundle evidence stays unconfirmed', () {
      final result = engine.decide(
        aggregate(
          serviceKey: 'JIOHOTSTAR',
          evidences: <SubscriptionEvidence>[
            evidence(SubscriptionEvidenceKind.paidCharge, 1),
            evidence(SubscriptionEvidenceKind.bundleBenefit, 1),
          ],
          intervals: const <int>[30],
        ),
      );

      expect(result, ServiceDecisionState.possibleButUnconfirmed);
    });

    test('single annual paid charge is confirmed only with strong merchant match', () {
      final confirmedResult = engine.decide(
        aggregate(
          serviceKey: 'ADOBE_SYSTEMS',
          evidences: <SubscriptionEvidence>[
            evidence(SubscriptionEvidenceKind.paidCharge, 1),
          ],
          amounts: const <double>[1499],
          hasStrongMerchantMatch: true,
        ),
      );

      final unresolvedResult = engine.decide(
        aggregate(
          serviceKey: 'UNRESOLVED',
          evidences: <SubscriptionEvidence>[
            evidence(SubscriptionEvidenceKind.paidCharge, 1),
          ],
          amounts: const <double>[1499],
          hasStrongMerchantMatch: false,
        ),
      );

      expect(confirmedResult, ServiceDecisionState.confirmedPaid);
      expect(unresolvedResult, ServiceDecisionState.possibleButUnconfirmed);
    });
    test('noise-only evidence stays hidden', () {
      final result = engine.decide(
        aggregate(
          serviceKey: 'UNRESOLVED',
          evidences: <SubscriptionEvidence>[
            evidence(SubscriptionEvidenceKind.otpNoise, 1),
            evidence(SubscriptionEvidenceKind.promoNoise, 1),
          ],
          hasStrongMerchantMatch: false,
        ),
      );

      expect(result, ServiceDecisionState.hiddenNoise);
    });
  });
}

