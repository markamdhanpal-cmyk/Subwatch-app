import '../../../domain/entities/evidence_trail.dart';
import '../../../domain/entities/service_evidence_bucket.dart';
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
}
