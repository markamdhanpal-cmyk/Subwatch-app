/// Represents the billing frequency of a subscription.
///
/// This is a first-class domain concept used for structured truth.
/// Presentation labels (e.g. "Monthly", "Yearly") should be derived from
/// this enum, not the other way around.
enum BillingCadence {
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  annual,
  unknown;

  /// Infers cadence from the number of days between billed events.
  static BillingCadence fromIntervalDays(int days) {
    if (days >= 5 && days <= 9) return BillingCadence.weekly;
    if (days >= 25 && days <= 35) return BillingCadence.monthly;
    if (days >= 80 && days <= 100) return BillingCadence.quarterly;
    if (days >= 165 && days <= 200) return BillingCadence.semiAnnual;
    if (days >= 350 && days <= 380) return BillingCadence.annual;
    return BillingCadence.unknown;
  }

  /// Infers cadence from explicit keywords in evidence notes.
  static BillingCadence fromNotes(List<String> notes) {
    final joined = notes.join(' ').toLowerCase();
    if (joined.contains('annual') || joined.contains('yearly')) {
      return BillingCadence.annual;
    }
    if (joined.contains('semi-annual') ||
        joined.contains('semi annual') ||
        joined.contains('6-month') ||
        joined.contains('6 month')) {
      return BillingCadence.semiAnnual;
    }
    if (joined.contains('quarterly') || joined.contains('every 3 months')) {
      return BillingCadence.quarterly;
    }
    if (joined.contains('monthly')) {
      return BillingCadence.monthly;
    }
    if (joined.contains('weekly')) {
      return BillingCadence.weekly;
    }
    return BillingCadence.unknown;
  }
}
