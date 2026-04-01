import '../enums/billing_cadence.dart';
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
    this.lastBilledAmount,
    this.billingCadence = BillingCadence.unknown,
    this.nextRenewalDate,
  });

  final ServiceKey serviceKey;
  final ResolverState state;
  final EvidenceTrail evidenceTrail;
  final SubscriptionEventType? lastEventType;
  final DateTime? lastEventAt;
  final double totalBilled;

  /// The most recent individual billing amount observed.
  /// Used by totals projection as structured truth instead of parsing
  /// presentation strings.
  final double? lastBilledAmount;

  /// The inferred billing cadence based on interval evidence.
  /// Used by totals projection for monthly-equivalent conversion.
  final BillingCadence billingCadence;
  
  /// The structured next renewal date if known.
  /// Used by upcoming renewals projection to avoid parsing subtitle.
  final DateTime? nextRenewalDate;

  ServiceLedgerEntry copyWith({
    ResolverState? state,
    EvidenceTrail? evidenceTrail,
    SubscriptionEventType? lastEventType,
    DateTime? lastEventAt,
    double? totalBilled,
    double? lastBilledAmount,
    BillingCadence? billingCadence,
    DateTime? nextRenewalDate,
  }) {
    return ServiceLedgerEntry(
      serviceKey: serviceKey,
      state: state ?? this.state,
      evidenceTrail: evidenceTrail ?? this.evidenceTrail,
      lastEventType: lastEventType ?? this.lastEventType,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      totalBilled: totalBilled ?? this.totalBilled,
      lastBilledAmount: lastBilledAmount ?? this.lastBilledAmount,
      billingCadence: billingCadence ?? this.billingCadence,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
    );
  }
}
