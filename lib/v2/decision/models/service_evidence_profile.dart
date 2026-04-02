import '../../../domain/entities/subscription_evidence.dart';
import '../../../domain/enums/subscription_evidence_kind.dart';
import '../../../domain/value_objects/service_key.dart';

class ServiceEvidenceProfile {
  ServiceEvidenceProfile({
    required this.serviceKey,
    required List<SubscriptionEvidence> evidences,
  }) : evidences = List<SubscriptionEvidence>.unmodifiable(evidences);

  final ServiceKey serviceKey;
  final List<SubscriptionEvidence> evidences;

  int countFor(SubscriptionEvidenceKind kind) {
    for (final evidence in evidences) {
      if (evidence.kind == kind) {
        return evidence.count;
      }
    }

    return 0;
  }

  bool has(SubscriptionEvidenceKind kind) => countFor(kind) > 0;
}
