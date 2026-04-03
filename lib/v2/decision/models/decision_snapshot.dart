import '../../../domain/entities/evidence_trail.dart';
import '../../../domain/entities/service_evidence_bucket.dart';
import '../../../domain/enums/service_decision_state.dart';
import '../../../domain/value_objects/service_key.dart';
import '../../scoring/models/subscription_score.dart';
import '../enums/decision_band.dart';
import '../enums/decision_reason_code.dart';

class DecisionSnapshot {
  DecisionSnapshot({
    required this.serviceKey,
    required this.band,
    required this.decidedAt,
    required List<DecisionReasonCode> reasonCodes,
    required List<String> notes,
    required this.evidenceTrail,
    required this.sourceBucket,
    required this.subscriptionScore,
    this.lastBilledAt,
    this.bridgeTotalBilled = 0,
    this.schemaVersion = 2,
  })  : reasonCodes = List<DecisionReasonCode>.unmodifiable(reasonCodes),
        notes = List<String>.unmodifiable(notes);

  final int schemaVersion;
  final ServiceKey serviceKey;
  final DecisionBand band;
  final DateTime decidedAt;
  final DateTime? lastBilledAt;
  final double bridgeTotalBilled;
  final List<DecisionReasonCode> reasonCodes;
  final List<String> notes;
  final EvidenceTrail evidenceTrail;
  final ServiceEvidenceBucket sourceBucket;
  final SubscriptionScore subscriptionScore;

  bool get isPaidTruth => band.isConfirmedPaidTruth;

  bool get isIncludedBenefit => band.isIncludedBenefit;

  bool get isConservativePossible => band.isConservativePossible;

  ServiceDecisionState get decisionState {
    switch (band) {
      case DecisionBand.confirmedPaid:
        return ServiceDecisionState.confirmedPaid;
      case DecisionBand.includedWithPlan:
        return ServiceDecisionState.includedWithPlan;
      case DecisionBand.setupOnly:
      case DecisionBand.verificationOnly:
        return ServiceDecisionState.setupOnly;
      case DecisionBand.likelyPaid:
      case DecisionBand.needsReview:
        return ServiceDecisionState.possibleButUnconfirmed;
      case DecisionBand.ended:
        return ServiceDecisionState.ended;
      case DecisionBand.oneTimeOrNoise:
      case DecisionBand.ignored:
        return ServiceDecisionState.hiddenNoise;
    }
  }
}
