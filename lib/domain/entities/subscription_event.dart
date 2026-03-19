import '../enums/subscription_event_type.dart';
import '../value_objects/service_key.dart';
import 'evidence_trail.dart';

class SubscriptionEvent {
  const SubscriptionEvent({
    required this.id,
    required this.serviceKey,
    required this.type,
    required this.occurredAt,
    required this.sourceMessageId,
    required this.evidenceTrail,
    this.amount,
  });

  final String id;
  final ServiceKey serviceKey;
  final SubscriptionEventType type;
  final DateTime occurredAt;
  final String sourceMessageId;
  final EvidenceTrail evidenceTrail;
  final double? amount;
}
