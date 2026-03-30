import '../../../domain/entities/evidence_trail.dart';
import '../../../domain/entities/service_ledger_entry.dart';
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
      lastEventAt: snapshot.decidedAt,
      totalBilled: _totalBilledFor(snapshot, currentEntry),
    );
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

  double _totalBilledFor(
    DecisionSnapshot snapshot,
    ServiceLedgerEntry? currentEntry,
  ) {
    if (snapshot.band != DecisionBand.confirmedPaid &&
        snapshot.band != DecisionBand.likelyPaid) {
      return 0;
    }

    final currentTotal = currentEntry?.totalBilled ?? 0;
    if (currentTotal > 0) {
      return currentTotal;
    }

    return snapshot.bridgeTotalBilled;
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
