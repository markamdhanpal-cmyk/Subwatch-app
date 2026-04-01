import '../models/dashboard_totals_summary_presentation.dart';
import '../models/manual_subscription_models.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/enums/billing_cadence.dart';
import '../../domain/enums/dashboard_bucket.dart';
import '../../domain/enums/resolver_state.dart';

class BuildDashboardTotalsSummaryUseCase {
  const BuildDashboardTotalsSummaryUseCase();

  DashboardTotalsSummaryPresentation execute({
    required List<DashboardCard> cards,
    List<ManualSubscriptionEntry> manualSubscriptions =
        const <ManualSubscriptionEntry>[],
    int? reviewCount,
  }) {
    final confirmedPaidCards = cards
        .where(
          (card) =>
              card.bucket == DashboardBucket.confirmedSubscriptions &&
              card.state == ResolverState.activePaid,
        )
        .toList(growable: false);

    final surfacedReviewCount =
        reviewCount ??
        cards.where((card) => card.bucket == DashboardBucket.needsReview).length;

    var includedInMonthlyTotalCount = 0;
    var excludedWithoutTrustedAmountCount = 0;
    var manualEntriesIncludedCount = 0;
    var manualEntriesExcludedWithoutAmountCount = 0;
    var cadenceConvertedCount = 0;
    var inferredMonthlyCount = 0;
    var monthlyTotalAmount = 0.0;

    for (final card in confirmedPaidCards) {
      // Use structured amount directly — no more subtitle parsing.
      final amount = card.structuredAmount;
      if (amount == null || amount <= 0) {
        excludedWithoutTrustedAmountCount += 1;
        continue;
      }

      // Use structured cadence directly — no more subtitle regex.
      final cadence = card.structuredCadence;
      if (cadence == BillingCadence.unknown) {
        inferredMonthlyCount += 1;
      }
      if (cadence == BillingCadence.quarterly ||
          cadence == BillingCadence.semiAnnual ||
          cadence == BillingCadence.annual) {
        cadenceConvertedCount += 1;
      }

      includedInMonthlyTotalCount += 1;
      monthlyTotalAmount += _monthlyEquivalentForAmount(
        amount,
        cadence: cadence,
      );
    }

    for (final entry in manualSubscriptions) {
      if (!entry.hasAmount) {
        manualEntriesExcludedWithoutAmountCount += 1;
        continue;
      }

      manualEntriesIncludedCount += 1;
      if (entry.billingCycle == ManualSubscriptionBillingCycle.yearly) {
        cadenceConvertedCount += 1;
      }
      monthlyTotalAmount += _monthlyEquivalentForManualEntry(entry);
    }

    return DashboardTotalsSummaryPresentation(
      activePaidCount: confirmedPaidCards.length,
      reviewCount: surfacedReviewCount,
      includedInMonthlyTotalCount: includedInMonthlyTotalCount,
      excludedWithoutTrustedAmountCount: excludedWithoutTrustedAmountCount,
      manualEntriesIncludedCount: manualEntriesIncludedCount,
      manualEntriesExcludedWithoutAmountCount:
          manualEntriesExcludedWithoutAmountCount,
      cadenceConvertedCount: cadenceConvertedCount,
      inferredMonthlyCount: inferredMonthlyCount,
      monthlyTotalAmount: monthlyTotalAmount,
    );
  }

  double _monthlyEquivalentForAmount(
    double amount, {
    required BillingCadence cadence,
  }) {
    switch (cadence) {
      case BillingCadence.annual:
        return amount / 12;
      case BillingCadence.semiAnnual:
        return amount / 6;
      case BillingCadence.quarterly:
        return amount / 3;
      case BillingCadence.weekly:
        return amount * 4.33; // approximate weeks per month
      case BillingCadence.monthly:
      case BillingCadence.unknown:
        return amount;
    }
  }

  double _monthlyEquivalentForManualEntry(ManualSubscriptionEntry entry) {
    final amount = (entry.amountInMinorUnits ?? 0) / 100;
    switch (entry.billingCycle) {
      case ManualSubscriptionBillingCycle.monthly:
        return amount;
      case ManualSubscriptionBillingCycle.yearly:
        return amount / 12;
    }
  }
}

