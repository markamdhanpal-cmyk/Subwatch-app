import '../contracts/dashboard_projection.dart';
import '../entities/dashboard_card.dart';
import '../entities/review_item.dart';
import '../entities/service_ledger_entry.dart';
import '../enums/dashboard_bucket.dart';
import '../enums/resolver_state.dart';

class DeterministicDashboardProjection implements DashboardProjection {
  const DeterministicDashboardProjection();

  @override
  List<DashboardCard> buildCards(Iterable<ServiceLedgerEntry> entries) {
    final sortedEntries = entries.toList(growable: false)
      ..sort((left, right) =>
          left.serviceKey.value.compareTo(right.serviceKey.value));

    return List<DashboardCard>.unmodifiable(
      sortedEntries.map(
        (entry) => DashboardCard(
          serviceKey: entry.serviceKey,
          bucket: bucketForState(entry.state),
          title: entry.serviceKey.displayName,
          subtitle: _subtitleForEntry(entry),
          state: entry.state,
          amountLabel: _amountLabelForEntry(entry),
          frequencyLabel: _frequencyLabelForEntry(entry),
        ),
      ),
    );
  }

  @override
  List<ReviewItem> buildReviewQueue(Iterable<ServiceLedgerEntry> entries) {
    final reviewEntries = entries
        .where((entry) =>
            isReviewEligible(entry.state))
        .toList(growable: false)
      ..sort((left, right) =>
          left.serviceKey.value.compareTo(right.serviceKey.value));

    return List<ReviewItem>.unmodifiable(
      reviewEntries.map(
        (entry) => ReviewItem(
          serviceKey: entry.serviceKey,
          title: entry.serviceKey.displayName,
          rationale: _reviewRationale(entry.state),
          evidenceTrail: entry.evidenceTrail,
        ),
      ),
    );
  }

  DashboardBucket bucketForState(ResolverState state) {
    switch (state) {
      case ResolverState.activePaid:
        return DashboardBucket.confirmedSubscriptions;
      case ResolverState.pendingConversion:
      case ResolverState.verificationOnly:
      case ResolverState.possibleSubscription:
        return DashboardBucket.needsReview;
      case ResolverState.activeBundled:
        return DashboardBucket.trialsAndBenefits;
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        return DashboardBucket.hidden;
    }
  }

  bool isReviewEligible(ResolverState state) {
    switch (state) {
      case ResolverState.pendingConversion:
      case ResolverState.verificationOnly:
      case ResolverState.possibleSubscription:
        return true;
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
            ? 'Confirmed paid subscription'
            : 'Confirmed paid subscription - \u20B9$billed';
      case ResolverState.pendingConversion:
        return 'Mandate or autopay setup detected';
      case ResolverState.verificationOnly:
        return 'Micro verification detected';
      case ResolverState.possibleSubscription:
        return 'Needs confirmation';
      case ResolverState.activeBundled:
        return 'Bundled with your plan';
      case ResolverState.ignored:
        return 'Ignored activity';
      case ResolverState.oneTimeOnly:
        return 'One-time payment';
      case ResolverState.cancelled:
        return 'Cancelled';
    }
  }

  String? _amountLabelForEntry(ServiceLedgerEntry entry) {
    if (entry.totalBilled <= 0) {
      return null;
    }

    final wholeUnits = entry.totalBilled.toStringAsFixed(0);
    return '\u20B9$wholeUnits';
  }

  String? _frequencyLabelForEntry(ServiceLedgerEntry entry) {
    final notes = entry.evidenceTrail.notes.join(' ').toLowerCase();
    if (notes.contains('quarterly')) {
      return 'Quarterly';
    }
    if (notes.contains('annual') || notes.contains('yearly')) {
      return 'Yearly';
    }
    if (notes.contains('monthly')) {
      return 'Monthly';
    }
    if (notes.contains('weekly')) {
      return 'Weekly';
    }
    return null;
  }

  String _reviewRationale(ResolverState state) {
    switch (state) {
      case ResolverState.pendingConversion:
        return 'Setup intent seen, but no billed evidence yet.';
      case ResolverState.verificationOnly:
        return 'Only micro verification evidence has been seen so far.';
      case ResolverState.possibleSubscription:
        return 'Possible subscription requires confirmation.';
      case ResolverState.activePaid:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        return 'No review required.';
    }
  }
}
