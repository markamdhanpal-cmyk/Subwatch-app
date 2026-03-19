import '../models/dashboard_totals_summary_presentation.dart';
import '../models/manual_subscription_models.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/enums/dashboard_bucket.dart';
import '../../domain/enums/resolver_state.dart';

class BuildDashboardTotalsSummaryUseCase {
  const BuildDashboardTotalsSummaryUseCase();

  static final RegExp _rupeeAmountPattern = RegExp(
    r'\bRs\s+([0-9]+(?:,[0-9]{3})*(?:\.[0-9]+)?)\b',
    caseSensitive: false,
  );
  static final RegExp _yearlyPattern = RegExp(
    r'\b(?:yearly|annual|annually|per year|year plan|annual plan)\b',
    caseSensitive: false,
  );
  static final RegExp _quarterlyPattern = RegExp(
    r'\b(?:quarterly|every 3 months|per quarter|quarter plan)\b',
    caseSensitive: false,
  );
  static final RegExp _monthlyPattern = RegExp(
    r'\b(?:monthly|per month|month plan)\b',
    caseSensitive: false,
  );

  DashboardTotalsSummaryPresentation execute({
    required List<DashboardCard> cards,
    List<ManualSubscriptionEntry> manualSubscriptions =
        const <ManualSubscriptionEntry>[],
  }) {
    final confirmedPaidCards = cards
        .where(
          (card) =>
              card.bucket == DashboardBucket.confirmedSubscriptions &&
              card.state == ResolverState.activePaid,
        )
        .toList(growable: false);
    final reviewCount = cards
        .where((card) => card.bucket == DashboardBucket.needsReview)
        .length;

    var includedInMonthlyTotalCount = 0;
    var excludedWithoutTrustedAmountCount = 0;
    var manualEntriesIncludedCount = 0;
    var manualEntriesExcludedWithoutAmountCount = 0;
    var cadenceConvertedCount = 0;
    var inferredMonthlyCount = 0;
    var monthlyTotalAmount = 0.0;

    for (final card in confirmedPaidCards) {
      final amount = _extractTrustedVisibleAmount(card.subtitle);
      if (amount == null) {
        excludedWithoutTrustedAmountCount += 1;
        continue;
      }

      final cadence = _cadenceForSubtitle(card.subtitle);
      if (cadence == _BillingCadence.unknown) {
        inferredMonthlyCount += 1;
      }
      if (cadence == _BillingCadence.quarterly ||
          cadence == _BillingCadence.yearly) {
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
      reviewCount: reviewCount,
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

  double? _extractTrustedVisibleAmount(String subtitle) {
    final match = _rupeeAmountPattern.firstMatch(subtitle);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  double _monthlyEquivalentForAmount(
    double amount, {
    required _BillingCadence cadence,
  }) {
    switch (cadence) {
      case _BillingCadence.yearly:
        return amount / 12;
      case _BillingCadence.quarterly:
        return amount / 3;
      case _BillingCadence.monthly:
      case _BillingCadence.unknown:
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

  _BillingCadence _cadenceForSubtitle(String subtitle) {
    if (_yearlyPattern.hasMatch(subtitle)) {
      return _BillingCadence.yearly;
    }
    if (_quarterlyPattern.hasMatch(subtitle)) {
      return _BillingCadence.quarterly;
    }
    if (_monthlyPattern.hasMatch(subtitle)) {
      return _BillingCadence.monthly;
    }
    return _BillingCadence.unknown;
  }
}

enum _BillingCadence {
  monthly,
  quarterly,
  yearly,
  unknown,
}
