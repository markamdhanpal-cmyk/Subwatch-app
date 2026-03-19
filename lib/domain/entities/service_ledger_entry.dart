import '../enums/resolver_state.dart';
import '../enums/subscription_event_type.dart';
import '../value_objects/service_key.dart';
import 'evidence_trail.dart';

class ServiceLedgerEntry {
  const ServiceLedgerEntry({
    required this.serviceKey,
    required this.state,
    required this.evidenceTrail,
    this.lastEventType,
    this.lastEventAt,
    this.totalBilled = 0,
  });

  final ServiceKey serviceKey;
  final ResolverState state;
  final EvidenceTrail evidenceTrail;
  final SubscriptionEventType? lastEventType;
  final DateTime? lastEventAt;
  final double totalBilled;

  ServiceLedgerEntry copyWith({
    ResolverState? state,
    EvidenceTrail? evidenceTrail,
    SubscriptionEventType? lastEventType,
    DateTime? lastEventAt,
    double? totalBilled,
  }) {
    return ServiceLedgerEntry(
      serviceKey: serviceKey,
      state: state ?? this.state,
      evidenceTrail: evidenceTrail ?? this.evidenceTrail,
      lastEventType: lastEventType ?? this.lastEventType,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      totalBilled: totalBilled ?? this.totalBilled,
    );
  }
}
