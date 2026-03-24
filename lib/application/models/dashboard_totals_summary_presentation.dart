class DashboardTotalsSummaryPresentation {
  const DashboardTotalsSummaryPresentation({
    required this.activePaidCount,
    required this.reviewCount,
    required this.includedInMonthlyTotalCount,
    required this.excludedWithoutTrustedAmountCount,
    required this.manualEntriesIncludedCount,
    required this.manualEntriesExcludedWithoutAmountCount,
    required this.cadenceConvertedCount,
    required this.inferredMonthlyCount,
    required this.monthlyTotalAmount,
  });

  final int activePaidCount;
  final int reviewCount;
  final int includedInMonthlyTotalCount;
  final int excludedWithoutTrustedAmountCount;
  final int manualEntriesIncludedCount;
  final int manualEntriesExcludedWithoutAmountCount;
  final int cadenceConvertedCount;
  final int inferredMonthlyCount;
  final double monthlyTotalAmount;

  bool get showSummary => true;

  int get totalIncludedAmountSources =>
      includedInMonthlyTotalCount + manualEntriesIncludedCount;

  int get totalMissingAmountSources =>
      excludedWithoutTrustedAmountCount +
      manualEntriesExcludedWithoutAmountCount;

  bool get hasEstimatedSpend => totalIncludedAmountSources > 0;

  bool get isPartialEstimate => totalMissingAmountSources > 0;

  bool get hasCadenceConversions => cadenceConvertedCount > 0;

  bool get hasInference => inferredMonthlyCount > 0;

  String get activePaidValueLabel => '$activePaidCount';

  String get activePaidCaption =>
      activePaidCount == 1 ? 'Confirmed service' : 'Confirmed services';

  String get reviewValueLabel => '$reviewCount';

  String get reviewCaption =>
      reviewCount == 1 ? 'Review item' : 'Review items';

  String get monthlyTotalValueLabel => !hasEstimatedSpend
      ? 'Amount not available yet'
      : '\u20B9${monthlyTotalAmount.toStringAsFixed(0)}';

  String get estimateBadgeLabel {
    if (!hasEstimatedSpend) {
      return 'Amount pending';
    }
    if (isPartialEstimate) {
      return 'Partial estimate';
    }
    return 'Estimated';
  }

  String get monthlyTotalCaption {
    if (!hasEstimatedSpend) {
      return 'Appears when an amount is visible';
    }
    if (isPartialEstimate) {
      return 'Some services still need amounts';
    }
    if (hasCadenceConversions) {
      return 'Yearly plans shown monthly';
    }
    return 'Using visible amounts';
  }

  String get summaryCopy {
    if (!hasEstimatedSpend) {
      return 'Monthly spend appears after SubWatch finds an amount.';
    }
    if (isPartialEstimate && hasCadenceConversions) {
      return 'Missing amounts are excluded. Yearly plans are shown monthly.';
    }
    if (isPartialEstimate) {
      return 'Services without amounts are excluded.';
    }
    if (hasCadenceConversions) {
      return 'Yearly plans are shown monthly.';
    }
    if (manualEntriesIncludedCount > 0) {
      return 'Includes visible amounts and manual entries with amounts.';
    }
    return 'Uses visible confirmed subscription amounts.';
  }

  String get explainerTitle => 'What totals include';

  List<String> get explainerBullets => <String>[
        'Only confirmed subscriptions with visible amounts count automatically.',
        'Manual entries with amounts count on this phone.',
        'Yearly and quarterly plans are shown monthly.',
        'Review, benefits, and missing amounts stay excluded.',
        'This is an estimate, not exact spend.',
      ];
}
