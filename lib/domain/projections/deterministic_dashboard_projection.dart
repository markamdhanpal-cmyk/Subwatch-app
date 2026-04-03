import '../contracts/dashboard_projection.dart';
import '../entities/dashboard_card.dart';
import '../entities/review_item.dart';
import '../entities/service_ledger_entry.dart';
import '../enums/billing_cadence.dart';
import '../enums/dashboard_bucket.dart';
import '../enums/resolver_state.dart';
import '../services/legacy_service_key_trust_guard.dart';

class DeterministicDashboardProjection implements DashboardProjection {
  const DeterministicDashboardProjection();

  @override
  List<DashboardCard> buildCards(Iterable<ServiceLedgerEntry> entries) {
    final sortedEntries = entries.toList(growable: false)
      ..sort(
        (left, right) =>
            left.serviceKey.value.compareTo(right.serviceKey.value),
      );

    final cards = <DashboardCard>[];
    for (final entry in sortedEntries) {
      if (entry.serviceKey.value ==
          LegacyServiceKeyTrustGuard.unresolvedServiceKey) {
        continue;
      }

      cards.add(
        DashboardCard(
          serviceKey: entry.serviceKey,
          bucket: bucketForState(entry.state),
          title: entry.serviceKey.displayName,
          subtitle: _subtitleForEntry(entry),
          state: entry.state,
          amountLabel: _amountLabelForEntry(entry),
          frequencyLabel: _frequencyLabelForEntry(entry),
          structuredAmount: _structuredAmountFor(entry),
          structuredCadence: _structuredCadenceFor(entry),
          structuredNextRenewalDate: _structuredNextRenewalFor(entry),
        ),
      );
    }

    return List<DashboardCard>.unmodifiable(cards);
  }

  @override
  List<ReviewItem> buildReviewQueue(Iterable<ServiceLedgerEntry> entries) {
    final items = <ReviewItem>[];

    for (final entry in entries) {
      if (!isReviewEligible(entry.state)) {
        continue;
      }
      if (entry.serviceKey.value ==
          LegacyServiceKeyTrustGuard.unresolvedServiceKey) {
        continue;
      }

      items.add(
        ReviewItem(
          serviceKey: entry.serviceKey,
          title: entry.serviceKey.displayName,
          rationale: _reviewRationaleFor(entry.state),
          evidenceTrail: entry.evidenceTrail,
          reasonLine: _reviewReasonLineFor(entry.state),
          detailsBullets: _reviewDetailsFor(entry.state),
          priorityScore: _reviewPriorityScore(entry),
        ),
      );
    }

    items.sort((left, right) {
      final priorityCompare = right.priorityScore.compareTo(left.priorityScore);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return left.serviceKey.value.compareTo(right.serviceKey.value);
    });

    return List<ReviewItem>.unmodifiable(items);
  }

  DashboardBucket bucketForState(ResolverState state) {
    switch (state) {
      case ResolverState.activePaid:
        return DashboardBucket.confirmedSubscriptions;
      case ResolverState.pendingConversion:
      case ResolverState.verificationOnly:
      case ResolverState.possibleSubscription:
        return DashboardBucket.hidden;
      case ResolverState.activeBundled:
        return DashboardBucket.trialsAndBenefits;
      case ResolverState.cancelled:
        return DashboardBucket.endedSubscriptions;
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
        return DashboardBucket.hidden;
    }
  }

  bool isReviewEligible(ResolverState state) {
    switch (state) {
      case ResolverState.pendingConversion:
      case ResolverState.verificationOnly:
        return true;
      case ResolverState.possibleSubscription:
      case ResolverState.activePaid:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        return false;
    }
  }

  String _subtitleForEntry(ServiceLedgerEntry entry) {
    switch (entry.state) {
      case ResolverState.activePaid:
        final billed = entry.totalBilled.toStringAsFixed(0);
        return billed == '0'
            ? 'Confirmed from billed renewal evidence'
            : 'Confirmed from billed renewal evidence - Rs $billed';
      case ResolverState.pendingConversion:
        return 'Setup detected, not billed';
      case ResolverState.verificationOnly:
        return 'Setup detected, verification charge only';
      case ResolverState.possibleSubscription:
        return 'Possible, waiting for billed proof';
      case ResolverState.activeBundled:
        return 'Included with your mobile plan';
      case ResolverState.ignored:
        return 'Ignored activity';
      case ResolverState.oneTimeOnly:
        return 'One-time payment';
      case ResolverState.cancelled:
        return 'Ended';
    }
  }

  String? _amountLabelForEntry(ServiceLedgerEntry entry) {
    if (!_canExposePaidAmounts(entry.state)) {
      return null;
    }

    final amount =
        (entry.lastBilledAmount != null && entry.lastBilledAmount! > 0)
            ? entry.lastBilledAmount!
            : entry.totalBilled;
    if (amount <= 0) {
      return null;
    }
    return 'Rs ${amount.toStringAsFixed(0)}';
  }

  String? _frequencyLabelForEntry(ServiceLedgerEntry entry) {
    if (!_canExposePaidAmounts(entry.state)) {
      return null;
    }

    switch (entry.billingCadence) {
      case BillingCadence.weekly:
        return 'Weekly';
      case BillingCadence.monthly:
        return 'Monthly';
      case BillingCadence.quarterly:
        return 'Quarterly';
      case BillingCadence.semiAnnual:
        return 'Every 6 months';
      case BillingCadence.annual:
        return 'Yearly';
      case BillingCadence.unknown:
        return null;
    }
  }

  double? _structuredAmountFor(ServiceLedgerEntry entry) {
    if (!_canExposePaidAmounts(entry.state)) {
      return null;
    }
    return entry.lastBilledAmount;
  }

  BillingCadence _structuredCadenceFor(ServiceLedgerEntry entry) {
    if (!_canExposePaidAmounts(entry.state)) {
      return BillingCadence.unknown;
    }
    return entry.billingCadence;
  }

  DateTime? _structuredNextRenewalFor(ServiceLedgerEntry entry) {
    if (!_canExposePaidAmounts(entry.state)) {
      return null;
    }
    return entry.nextRenewalDate;
  }

  bool _canExposePaidAmounts(ResolverState state) {
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

  String _reviewReasonLineFor(ResolverState state) {
    switch (state) {
      case ResolverState.pendingConversion:
        return 'A recurring setup was found, but billing is still missing';
      case ResolverState.verificationOnly:
        return 'Possible recurring setup: only a small verification charge was found';
      case ResolverState.possibleSubscription:
      case ResolverState.activePaid:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        return 'No possible follow-up required';
    }
  }

  String _reviewRationaleFor(ResolverState state) {
    switch (state) {
      case ResolverState.pendingConversion:
        return 'A mandate or autopay setup was found, but no billed renewal has been seen yet.';
      case ResolverState.verificationOnly:
        return 'Only a micro verification charge has been seen so far, which is not enough to confirm a paid subscription.';
      case ResolverState.possibleSubscription:
      case ResolverState.activePaid:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        return 'No possible follow-up required.';
    }
  }

  List<String> _reviewDetailsFor(ResolverState state) {
    switch (state) {
      case ResolverState.pendingConversion:
        return const <String>[
          'We saw a mandate or autopay setup for this service.',
          'There is still no billed renewal to prove it is active and paid.',
          'SubWatch keeps setup messages separate from confirmed subscriptions.',
        ];
      case ResolverState.verificationOnly:
        return const <String>[
          'We saw a very small charge that looks like a payment check.',
          'Tiny verification charges do not prove an active paid subscription.',
          'SubWatch waits for a real billed renewal before confirming it.',
        ];
      case ResolverState.possibleSubscription:
      case ResolverState.activePaid:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        return const <String>[];
    }
  }

  double _reviewPriorityScore(ServiceLedgerEntry entry) {
    var base = 0.0;
    switch (entry.state) {
      case ResolverState.verificationOnly:
        base = 0.9;
        break;
      case ResolverState.pendingConversion:
        base = 0.8;
        break;
      case ResolverState.possibleSubscription:
      case ResolverState.activePaid:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        base = 0.0;
        break;
    }

    final reviewPriority = _parseDoubleNote(
      entry.evidenceTrail.notes,
      'v2:reviewPriority=',
    );
    return base + (reviewPriority * 0.45);
  }

  double _parseDoubleNote(List<String> notes, String prefix) {
    for (final note in notes) {
      if (!note.startsWith(prefix)) {
        continue;
      }
      final parsed = double.tryParse(note.substring(prefix.length));
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
  }
}
