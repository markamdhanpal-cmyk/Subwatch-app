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
      : 'Rs ${monthlyTotalAmount.toStringAsFixed(0)}';

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
      return 'Shown when a billed or manual amount is available';
    }
    if (isPartialEstimate) {
      return 'Some subscriptions do not show an amount yet';
    }
    if (hasCadenceConversions) {
      return 'Annual or quarterly plans converted monthly';
    }
    return 'Using visible subscription amounts';
  }

  String get summaryCopy {
    if (!hasEstimatedSpend) {
      return 'Monthly spend appears here after SubWatch finds a visible billed amount or you add one manually.';
    }
    if (isPartialEstimate && hasCadenceConversions) {
      return 'Estimate excludes subscriptions without an amount and converts annual or quarterly plans to monthly equivalents.';
    }
    if (isPartialEstimate) {
      return 'Estimate excludes subscriptions without a visible amount.';
    }
    if (hasCadenceConversions) {
      return 'Annual or quarterly plans are shown as monthly equivalents here.';
    }
    if (manualEntriesIncludedCount > 0) {
      return 'Estimate includes confirmed billed amounts plus manual entries with amounts.';
    }
    return 'Estimate uses all visible confirmed subscription amounts.';
  }

  String get explainerTitle => 'What totals include';

  List<String> get explainerBullets => <String>[
        'Only confirmed paid subscriptions with visible amounts are counted automatically.',
        'Manual entries with amounts are included when present on this device.',
        'Annual and quarterly amounts are converted into monthly equivalents.',
        'Review items, bundled benefits, and anything without a visible billed amount stay excluded.',
        'This is an estimated subscription view, not an exact bank-spend dashboard.',
      ];
}
