import '../contracts/resolver.dart';
import '../entities/evidence_trail.dart';
import '../entities/service_ledger_entry.dart';
import '../entities/subscription_event.dart';
import '../enums/resolver_state.dart';
import '../enums/subscription_event_type.dart';

class DeterministicResolver implements Resolver {
  const DeterministicResolver();

  @override
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
    );
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
          return currentState!;
        }
        return ResolverState.activeBundled;
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
}
