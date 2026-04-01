import '../../../domain/entities/evidence_trail.dart';
import '../../../domain/entities/service_ledger_entry.dart';
import '../../../domain/enums/billing_cadence.dart';
import '../../../domain/enums/resolver_state.dart';
import '../../../domain/enums/subscription_event_type.dart';
import '../enums/decision_band.dart';
import '../models/decision_snapshot.dart';

class DecisionSnapshotLedgerBridge {
  const DecisionSnapshotLedgerBridge();

  ServiceLedgerEntry map({
    required DecisionSnapshot snapshot,
    ServiceLedgerEntry? currentEntry,
  }) {
    return ServiceLedgerEntry(
      serviceKey: snapshot.serviceKey,
      state: _stateFor(snapshot.band),
      evidenceTrail: _mergeEvidence(
        snapshot: snapshot,
        currentEntry: currentEntry,
      ),
      lastEventType: _eventTypeFor(snapshot.band, snapshot),
      lastEventAt: snapshot.lastBilledAt,
      totalBilled: snapshot.bridgeTotalBilled,
      lastBilledAmount: _lastBilledAmountFor(snapshot, currentEntry),
      billingCadence: _inferCadence(snapshot, currentEntry),
      nextRenewalDate: _inferNextRenewalDate(snapshot, currentEntry),
    );
  }

  BillingCadence _inferCadence(
    DecisionSnapshot snapshot,
    ServiceLedgerEntry? currentEntry,
  ) {
    if (currentEntry != null &&
        currentEntry.billingCadence != BillingCadence.unknown) {
      return currentEntry.billingCadence;
    }

    // 1. Try notes first (highest trust for explicit markers)
    final fromNotes = BillingCadence.fromNotes(snapshot.notes);
    if (fromNotes != BillingCadence.unknown) {
      return fromNotes;
    }

    // 2. Try interval hints from the bucket
    final intervals = snapshot.sourceBucket.intervalHintsInDays;
    if (intervals.isNotEmpty) {
      // Use the last interval as it is the most recent "beat"
      final fromInterval = BillingCadence.fromIntervalDays(intervals.last);
      if (fromInterval != BillingCadence.unknown) {
        return fromInterval;
      }
    }

    return BillingCadence.unknown;
  }

  DateTime? _inferNextRenewalDate(
    DecisionSnapshot snapshot,
    ServiceLedgerEntry? currentEntry,
  ) {
    // If the ledger already has a next renewal date, keep it for now
    // (though in the future we might want to refresh it if we see a newer event)
    if (currentEntry?.nextRenewalDate != null) {
      return currentEntry!.nextRenewalDate;
    }

    final lastBilled = snapshot.lastBilledAt;
    if (lastBilled == null) {
      return null;
    }

    final cadence = _inferCadence(snapshot, currentEntry);
    if (cadence == BillingCadence.unknown) {
      return null;
    }

    // Project next renewal based on cadence
    switch (cadence) {
      case BillingCadence.weekly:
        return lastBilled.add(const Duration(days: 7));
      case BillingCadence.monthly:
        return DateTime(
          lastBilled.year,
          lastBilled.month + 1,
          lastBilled.day,
        );
      case BillingCadence.quarterly:
        return DateTime(
          lastBilled.year,
          lastBilled.month + 3,
          lastBilled.day,
        );
      case BillingCadence.semiAnnual:
        return DateTime(
          lastBilled.year,
          lastBilled.month + 6,
          lastBilled.day,
        );
      case BillingCadence.annual:
        return DateTime(
          lastBilled.year + 1,
          lastBilled.month,
          lastBilled.day,
        );
      case BillingCadence.unknown:
        return null;
    }
  }

  ResolverState _stateFor(DecisionBand band) {
    switch (band) {
      case DecisionBand.confirmedPaid:
        return ResolverState.activePaid;
      case DecisionBand.likelyPaid:
      case DecisionBand.needsReview:
        return ResolverState.possibleSubscription;
      case DecisionBand.includedWithPlan:
        return ResolverState.activeBundled;
      case DecisionBand.setupOnly:
        return ResolverState.pendingConversion;
      case DecisionBand.verificationOnly:
        return ResolverState.verificationOnly;
      case DecisionBand.oneTimeOrNoise:
        return ResolverState.oneTimeOnly;
      case DecisionBand.ignored:
        return ResolverState.ignored;
    }
  }

  SubscriptionEventType _eventTypeFor(
    DecisionBand band,
    DecisionSnapshot snapshot,
  ) {
    switch (band) {
      case DecisionBand.confirmedPaid:
      case DecisionBand.likelyPaid:
        return SubscriptionEventType.subscriptionBilled;
      case DecisionBand.needsReview:
        return SubscriptionEventType.unknownReview;
      case DecisionBand.includedWithPlan:
        return SubscriptionEventType.bundleActivated;
      case DecisionBand.setupOnly:
        if (snapshot.sourceBucket.autopaySetupCount > 0) {
          return SubscriptionEventType.autopaySetup;
        }
        return SubscriptionEventType.mandateCreated;
      case DecisionBand.verificationOnly:
        return SubscriptionEventType.mandateExecutedMicro;
      case DecisionBand.oneTimeOrNoise:
        return SubscriptionEventType.oneTimePayment;
      case DecisionBand.ignored:
        return SubscriptionEventType.ignore;
    }
  }

  double? _lastBilledAmountFor(
    DecisionSnapshot snapshot,
    ServiceLedgerEntry? currentEntry,
  ) {
    if (currentEntry?.lastBilledAmount != null) {
      return currentEntry!.lastBilledAmount;
    }

    final amounts = snapshot.sourceBucket.amountSeries;
    if (amounts.isNotEmpty) {
      return amounts.last;
    }

    return null;
  }

  EvidenceTrail _mergeEvidence({
    required DecisionSnapshot snapshot,
    required ServiceLedgerEntry? currentEntry,
  }) {
    final currentEvidence = currentEntry?.evidenceTrail ?? EvidenceTrail.empty();
    final notes = <String>{
      ...currentEvidence.notes,
      ...snapshot.evidenceTrail.notes,
      'v2:band=${snapshot.band.name}',
      'v2:mlModel=${snapshot.subscriptionScore.modelVersion}',
      'v2:mlProbability=${snapshot.subscriptionScore.subscriptionProbability.toStringAsFixed(3)}',
      'v2:reviewPriority=${snapshot.subscriptionScore.reviewPriorityScore.toStringAsFixed(3)}',
      ...snapshot.reasonCodes.map((reason) => 'v2:reason=${reason.name}'),
      ...snapshot.notes.map((note) => 'v2:note=$note'),
    };

    return EvidenceTrail(
      messageIds: <String>[
        ...{...currentEvidence.messageIds, ...snapshot.evidenceTrail.messageIds},
      ],
      eventIds: <String>[
        ...{...currentEvidence.eventIds, ...snapshot.evidenceTrail.eventIds},
      ],
      notes: notes.toList(growable: false),
    );
  }
}
