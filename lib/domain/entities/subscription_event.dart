import 'evidence_fragment.dart';
import 'merchant_resolution.dart';
import '../enums/subscription_event_type.dart';
import '../value_objects/service_key.dart';
import 'evidence_trail.dart';

class SubscriptionEvent {
  SubscriptionEvent({
    required this.id,
    required this.serviceKey,
    required this.type,
    required this.occurredAt,
    required this.sourceMessageId,
    required this.evidenceTrail,
    this.merchantResolution,
    this.amount,
    List<EvidenceFragment> evidenceFragments = const <EvidenceFragment>[],
  }) : evidenceFragments = List<EvidenceFragment>.unmodifiable(evidenceFragments);

  final String id;
  final ServiceKey serviceKey;
  final SubscriptionEventType type;
  final DateTime occurredAt;
  final String sourceMessageId;
  final EvidenceTrail evidenceTrail;
  final MerchantResolution? merchantResolution;
  final double? amount;
  final List<EvidenceFragment> evidenceFragments;
}
