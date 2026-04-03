import '../../domain/entities/evidence_trail.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/enums/billing_cadence.dart';
import '../../domain/enums/resolver_state.dart';
import '../../domain/enums/subscription_event_type.dart';
import '../../domain/services/legacy_service_key_trust_guard.dart';
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
    final keepPaidAmounts = _stateCarriesPaidSemantics(entry.state);
    return PersistedServiceLedgerEntry(
      serviceKey: LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
        serviceKey: entry.serviceKey.value,
        evidenceNotes: entry.evidenceTrail.notes,
      ),
      state: entry.state.name,
      evidenceTrail: PersistedEvidenceTrail.fromDomain(entry.evidenceTrail),
      lastEventType: entry.lastEventType?.name,
      lastEventAt: entry.lastEventAt?.toIso8601String(),
      totalBilled: keepPaidAmounts ? entry.totalBilled : 0,
      lastBilledAmount: keepPaidAmounts ? entry.lastBilledAmount : null,
      billingCadence:
          keepPaidAmounts ? entry.billingCadence.name : BillingCadence.unknown.name,
    );
  }

  factory PersistedServiceLedgerEntry.fromJson(Map<String, Object?> json) {
    return PersistedServiceLedgerEntry(
      serviceKey: (json['serviceKey'] as String?)?.trim().isNotEmpty == true
          ? (json['serviceKey'] as String).trim()
          : LegacyServiceKeyTrustGuard.unresolvedServiceKey,
      state: (json['state'] as String?) ?? ResolverState.ignored.name,
      evidenceTrail: PersistedEvidenceTrail.fromJson(
        (json['evidenceTrail'] as Map?)
                ?.map((key, value) => MapEntry(key.toString(), value)) ??
            const <String, Object?>{},
      ),
      lastEventType: json['lastEventType'] as String?,
      lastEventAt: json['lastEventAt'] as String?,
      totalBilled: _nonNegativeAmount(json['totalBilled']),
      lastBilledAmount: _optionalNonNegativeAmount(json['lastBilledAmount']),
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
    final domainEvidenceTrail = evidenceTrail.toDomain();
    final sanitizedServiceKey =
        LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
      serviceKey: serviceKey,
      evidenceNotes: domainEvidenceTrail.notes,
    );

    final resolverState = _resolverStateFromName(state);
    final keepPaidAmounts = _stateCarriesPaidSemantics(resolverState);

    return ServiceLedgerEntry(
      serviceKey: ServiceKey(sanitizedServiceKey),
      state: resolverState,
      evidenceTrail: domainEvidenceTrail,
      lastEventType: lastEventType == null
          ? null
          : SubscriptionEventType.values.firstWhere(
              (value) => value.name == lastEventType,
              orElse: () => SubscriptionEventType.unknownReview,
            ),
      lastEventAt: lastEventAt == null ? null : DateTime.tryParse(lastEventAt!),
      totalBilled: keepPaidAmounts ? totalBilled : 0,
      lastBilledAmount: keepPaidAmounts ? lastBilledAmount : null,
      billingCadence: keepPaidAmounts
          ? _billingCadenceFromName(billingCadence)
          : BillingCadence.unknown,
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

  static bool _stateCarriesPaidSemantics(ResolverState state) {
    switch (state) {
      case ResolverState.activePaid:
      case ResolverState.cancelled:
        return true;
      case ResolverState.pendingConversion:
      case ResolverState.verificationOnly:
      case ResolverState.possibleSubscription:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
        return false;
    }
  }

  static ResolverState _resolverStateFromName(String value) {
    return ResolverState.values.firstWhere(
      (entry) => entry.name == value,
      orElse: () => ResolverState.ignored,
    );
  }

  static BillingCadence _billingCadenceFromName(String? value) {
    if (value == null) {
      return BillingCadence.unknown;
    }

    return BillingCadence.values.firstWhere(
      (entry) => entry.name == value,
      orElse: () => BillingCadence.unknown,
    );
  }

  static double _nonNegativeAmount(Object? value) {
    final parsed = (value as num?)?.toDouble() ?? 0;
    return parsed.isFinite && parsed > 0 ? parsed : 0;
  }

  static double? _optionalNonNegativeAmount(Object? value) {
    final parsed = (value as num?)?.toDouble();
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return null;
    }
    return parsed;
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
