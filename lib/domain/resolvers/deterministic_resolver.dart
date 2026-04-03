import '../contracts/resolver.dart';
import '../entities/evidence_trail.dart';
import '../entities/service_ledger_entry.dart';
import '../entities/subscription_event.dart';
import '../enums/billing_cadence.dart';
import '../enums/resolver_state.dart';
import '../enums/subscription_event_type.dart';

/// Legacy resolver retained for compatibility tests only.
/// Runtime default resolution now uses ServiceKeyResolverV2 + decision v3.
@Deprecated('Compatibility-only resolver. Prefer evidence-first v3 path.')
class DeterministicResolver implements Resolver {
  const DeterministicResolver();

  @override
  /// Resolves the current state of a subscription based on a new event.
  /// 
  /// PRECEDENCE RULES:
  /// 1. activePaid > activeBundled: A direct payment signal always overrides 
  ///    a bundled benefit signal for the same service.
  /// 2. subscriptionCancelled is terminal: Once cancelled, bundle signals 
  ///    will not resurrect the service.
  ServiceLedgerEntry resolve({
    required SubscriptionEvent event,
    ServiceLedgerEntry? currentEntry,
  }) {
    final nextState = _resolveState(
      eventType: event.type,
      currentState: currentEntry?.state,
    );

    final currentEvidence = currentEntry?.evidenceTrail ?? EvidenceTrail.empty();

    return ServiceLedgerEntry(
      serviceKey: event.serviceKey,
      state: nextState,
      evidenceTrail: _mergeEvidence(currentEvidence, event),
      lastEventType: event.type,
      lastEventAt: event.occurredAt,
      totalBilled: _nextTotalBilled(currentEntry, event, nextState),
      lastBilledAmount: _nextLastBilledAmount(currentEntry, event),
      billingCadence: _nextBillingCadence(currentEntry, event),
      nextRenewalDate: _nextNextRenewalDate(currentEntry, event),
    );
  }

  DateTime? _nextNextRenewalDate(
    ServiceLedgerEntry? currentEntry,
    SubscriptionEvent event,
  ) {
    if (event.type != SubscriptionEventType.subscriptionBilled) {
      return currentEntry?.nextRenewalDate;
    }

    final cadence = _nextBillingCadence(currentEntry, event);
    if (cadence == BillingCadence.unknown) {
      return null;
    }

    final occurredAt = event.occurredAt;
    switch (cadence) {
      case BillingCadence.weekly:
        return occurredAt.add(const Duration(days: 7));
      case BillingCadence.monthly:
        return DateTime(
          occurredAt.year,
          occurredAt.month + 1,
          occurredAt.day,
        );
      case BillingCadence.quarterly:
        return DateTime(
          occurredAt.year,
          occurredAt.month + 3,
          occurredAt.day,
        );
      case BillingCadence.semiAnnual:
        return DateTime(
          occurredAt.year,
          occurredAt.month + 6,
          occurredAt.day,
        );
      case BillingCadence.annual:
        return DateTime(
          occurredAt.year + 1,
          occurredAt.month,
          occurredAt.day,
        );
      case BillingCadence.unknown:
        return null;
    }
  }

  ResolverState _resolveState({
    required SubscriptionEventType eventType,
    required ResolverState? currentState,
  }) {
    switch (eventType) {
      case SubscriptionEventType.ignore:
        return currentState ?? ResolverState.ignored;
      case SubscriptionEventType.oneTimePayment:
        return currentState ?? ResolverState.oneTimeOnly;
      case SubscriptionEventType.mandateCreated:
      case SubscriptionEventType.autopaySetup:
        if (currentState == ResolverState.verificationOnly ||
            currentState == ResolverState.activePaid ||
            currentState == ResolverState.activeBundled ||
            currentState == ResolverState.cancelled) {
          return currentState!;
        }
        return ResolverState.pendingConversion;
      case SubscriptionEventType.mandateExecutedMicro:
        if (currentState == ResolverState.activePaid ||
            currentState == ResolverState.activeBundled ||
            currentState == ResolverState.cancelled) {
          return currentState!;
        }
        return ResolverState.verificationOnly;
      case SubscriptionEventType.subscriptionBilled:
        return ResolverState.activePaid;
      case SubscriptionEventType.bundleActivated:
        if (currentState == ResolverState.activePaid) {
          return ResolverState.activePaid;
        }
        if (currentState == ResolverState.cancelled) {
          return ResolverState.cancelled;
        }
        return ResolverState.activeBundled;
      case SubscriptionEventType.subscriptionCancelled:
        return ResolverState.cancelled;
      case SubscriptionEventType.unknownReview:
        if (currentState == ResolverState.activePaid ||
            currentState == ResolverState.activeBundled ||
            currentState == ResolverState.cancelled) {
          return currentState!;
        }
        if (currentState == ResolverState.pendingConversion ||
            currentState == ResolverState.verificationOnly ||
            currentState == ResolverState.possibleSubscription) {
          return currentState!;
        }
        return ResolverState.possibleSubscription;
    }
  }

  EvidenceTrail _mergeEvidence(EvidenceTrail current, SubscriptionEvent event) {
    final messageIds = <String>{
      ...current.messageIds,
      event.sourceMessageId,
      ...event.evidenceTrail.messageIds,
    };
    final eventIds = <String>{
      ...current.eventIds,
      event.id,
      ...event.evidenceTrail.eventIds,
    };
    final notes = <String>{
      ...current.notes,
      ...event.evidenceTrail.notes,
    };

    return EvidenceTrail(
      messageIds: messageIds.toList(growable: false),
      eventIds: eventIds.toList(growable: false),
      notes: notes.toList(growable: false),
    );
  }

  double _nextTotalBilled(
    ServiceLedgerEntry? currentEntry,
    SubscriptionEvent event,
    ResolverState nextState,
  ) {
    final currentTotal = currentEntry?.totalBilled ?? 0;
    if (nextState != ResolverState.activePaid ||
        event.type != SubscriptionEventType.subscriptionBilled) {
      return currentTotal;
    }

    return currentTotal + (event.amount ?? 0);
  }

  double? _nextLastBilledAmount(
    ServiceLedgerEntry? currentEntry,
    SubscriptionEvent event,
  ) {
    if (event.type == SubscriptionEventType.subscriptionBilled &&
        event.amount != null &&
        event.amount! > 0) {
      return event.amount;
    }
    return currentEntry?.lastBilledAmount;
  }

  BillingCadence _nextBillingCadence(
    ServiceLedgerEntry? currentEntry,
    SubscriptionEvent event,
  ) {
    // If there's an explicit cadence hint in the evidence trail notes,
    // use it directly.
    final cadenceFromNotes = _cadenceFromNotes(event.evidenceTrail.notes);
    if (cadenceFromNotes != BillingCadence.unknown) {
      return cadenceFromNotes;
    }

    // If this is a billed event and we have a previous billed date,
    // infer cadence from the interval.
    if (event.type == SubscriptionEventType.subscriptionBilled &&
        currentEntry?.lastEventAt != null &&
        currentEntry?.lastEventType ==
            SubscriptionEventType.subscriptionBilled) {
      final intervalDays =
          event.occurredAt.difference(currentEntry!.lastEventAt!).inDays;
      final inferred = _cadenceFromIntervalDays(intervalDays);
      if (inferred != BillingCadence.unknown) {
        return inferred;
      }
    }

    // Also check current entry's evidence trail
    if (currentEntry != null) {
      final existingCadence =
          _cadenceFromNotes(currentEntry.evidenceTrail.notes);
      if (existingCadence != BillingCadence.unknown) {
        return existingCadence;
      }
    }

    return currentEntry?.billingCadence ?? BillingCadence.unknown;
  }

  BillingCadence _cadenceFromNotes(List<String> notes) {
    return BillingCadence.fromNotes(notes);
  }

  /// Infers cadence from the number of days between billed events.
  BillingCadence _cadenceFromIntervalDays(int days) {
    return BillingCadence.fromIntervalDays(days);
  }
}




