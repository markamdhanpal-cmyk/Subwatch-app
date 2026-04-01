import '../../domain/entities/evidence_trail.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/enums/billing_cadence.dart';
import '../../domain/enums/resolver_state.dart';
import '../../domain/enums/subscription_event_type.dart';
import '../../domain/value_objects/service_key.dart';

class PersistedServiceLedgerEntry {
  const PersistedServiceLedgerEntry({
    required this.serviceKey,
    required this.state,
    required this.evidenceTrail,
    required this.totalBilled,
    this.lastEventType,
    this.lastEventAt,
    this.lastBilledAmount,
    this.billingCadence,
  });

  factory PersistedServiceLedgerEntry.fromDomain(ServiceLedgerEntry entry) {
    return PersistedServiceLedgerEntry(
      serviceKey: entry.serviceKey.value,
      state: entry.state.name,
      evidenceTrail: PersistedEvidenceTrail.fromDomain(entry.evidenceTrail),
      lastEventType: entry.lastEventType?.name,
      lastEventAt: entry.lastEventAt?.toIso8601String(),
      totalBilled: entry.totalBilled,
      lastBilledAmount: entry.lastBilledAmount,
      billingCadence: entry.billingCadence.name,
    );
  }

  factory PersistedServiceLedgerEntry.fromJson(Map<String, Object?> json) {
    return PersistedServiceLedgerEntry(
      serviceKey: json['serviceKey'] as String,
      state: json['state'] as String,
      evidenceTrail: PersistedEvidenceTrail.fromJson(
        json['evidenceTrail'] as Map<String, Object?>,
      ),
      lastEventType: json['lastEventType'] as String?,
      lastEventAt: json['lastEventAt'] as String?,
      totalBilled: (json['totalBilled'] as num?)?.toDouble() ?? 0,
      lastBilledAmount: (json['lastBilledAmount'] as num?)?.toDouble(),
      billingCadence: json['billingCadence'] as String?,
    );
  }

  final String serviceKey;
  final String state;
  final PersistedEvidenceTrail evidenceTrail;
  final String? lastEventType;
  final String? lastEventAt;
  final double totalBilled;
  final double? lastBilledAmount;
  final String? billingCadence;

  ServiceLedgerEntry toDomain() {
    return ServiceLedgerEntry(
      serviceKey: ServiceKey(serviceKey),
      state: ResolverState.values.firstWhere((value) => value.name == state),
      evidenceTrail: evidenceTrail.toDomain(),
      lastEventType: lastEventType == null
          ? null
          : SubscriptionEventType.values.firstWhere(
              (value) => value.name == lastEventType,
            ),
      lastEventAt: lastEventAt == null ? null : DateTime.parse(lastEventAt!),
      totalBilled: totalBilled,
      lastBilledAmount: lastBilledAmount,
      billingCadence: billingCadence == null
          ? BillingCadence.unknown
          : BillingCadence.values.firstWhere(
              (value) => value.name == billingCadence,
              orElse: () => BillingCadence.unknown,
            ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'serviceKey': serviceKey,
      'state': state,
      'evidenceTrail': evidenceTrail.toJson(),
      'lastEventType': lastEventType,
      'lastEventAt': lastEventAt,
      'totalBilled': totalBilled,
      'lastBilledAmount': lastBilledAmount,
      'billingCadence': billingCadence,
    };
  }
}

class PersistedEvidenceTrail {
  const PersistedEvidenceTrail({
    required this.messageIds,
    required this.eventIds,
    required this.notes,
  });

  factory PersistedEvidenceTrail.fromDomain(EvidenceTrail evidenceTrail) {
    return PersistedEvidenceTrail(
      messageIds: evidenceTrail.messageIds,
      eventIds: evidenceTrail.eventIds,
      notes: evidenceTrail.notes,
    );
  }

  factory PersistedEvidenceTrail.fromJson(Map<String, Object?> json) {
    return PersistedEvidenceTrail(
      messageIds: _readStringList(json['messageIds']),
      eventIds: _readStringList(json['eventIds']),
      notes: _readStringList(json['notes']),
    );
  }

  final List<String> messageIds;
  final List<String> eventIds;
  final List<String> notes;

  EvidenceTrail toDomain() {
    return EvidenceTrail(
      messageIds: messageIds,
      eventIds: eventIds,
      notes: notes,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'messageIds': messageIds,
      'eventIds': eventIds,
      'notes': notes,
    };
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return value.whereType<String>().toList(growable: false);
  }
}
