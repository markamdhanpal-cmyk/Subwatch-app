import '../enums/billing_cadence.dart';
import '../enums/dashboard_bucket.dart';
import '../enums/resolver_state.dart';
import '../value_objects/service_key.dart';

class DashboardCard {
  const DashboardCard({
    required this.serviceKey,
    required this.bucket,
    required this.title,
    required this.subtitle,
    required this.state,
    this.amountLabel,
    this.frequencyLabel,
    this.structuredAmount,
    this.structuredCadence = BillingCadence.unknown,
    this.structuredNextRenewalDate,
  });

  final ServiceKey serviceKey;
  final DashboardBucket bucket;
  final String title;
  final String subtitle;
  final ResolverState state;

  /// Presentation-only display string for the amount.
  final String? amountLabel;

  /// Presentation-only display string for the frequency.
  final String? frequencyLabel;

  /// The structured last-billed amount from the ledger.
  /// Used by totals projection as structured truth.
  final double? structuredAmount;

  /// The structured billing cadence from the ledger.
  /// Used by totals projection for monthly-equivalent conversion.
  final BillingCadence structuredCadence;

  /// The structured next renewal date from the ledger.
  /// Used by upcoming renewals projection to avoid parsing subtitle.
  final DateTime? structuredNextRenewalDate;
}
