import '../../application/models/manual_subscription_models.dart';

/// A popular subscription service with suggested defaults for manual add.
class PopularServiceEntry {
  const PopularServiceEntry({
    required this.name,
    required this.serviceKey,
    this.suggestedAmountInMinorUnits,
    this.billingCycle = ManualSubscriptionBillingCycle.monthly,
    this.planLabel,
  });

  /// Display name pre-filled into the service name field.
  final String name;

  /// Key matching [ServiceIconRegistry] for brand-colored avatar.
  final String serviceKey;

  /// Suggested amount in minor units (paise). User-editable.
  final int? suggestedAmountInMinorUnits;

  /// Default billing cycle. User-editable.
  final ManualSubscriptionBillingCycle billingCycle;

  /// Optional plan label hint. User-editable.
  final String? planLabel;
}

/// Catalog of popular subscription services for quick manual add.
///
/// Call [search] with a query to filter entries by name. Returns a copy
/// with only matching entries; the original list is never modified.
class PopularServiceCatalog {
  const PopularServiceCatalog._();

  static const List<PopularServiceEntry> entries = <PopularServiceEntry>[
    PopularServiceEntry(
      name: 'Netflix',
      serviceKey: 'NETFLIX',
      suggestedAmountInMinorUnits: 14900,
      planLabel: 'Basic',
    ),
    PopularServiceEntry(
      name: 'Spotify',
      serviceKey: 'SPOTIFY',
      suggestedAmountInMinorUnits: 11900,
    ),
    PopularServiceEntry(
      name: 'Amazon Prime',
      serviceKey: 'AMAZON_PRIME',
      suggestedAmountInMinorUnits: 14900,
      billingCycle: ManualSubscriptionBillingCycle.monthly,
    ),
    PopularServiceEntry(
      name: 'YouTube Premium',
      serviceKey: 'YOUTUBE_PREMIUM',
      suggestedAmountInMinorUnits: 14900,
    ),
    PopularServiceEntry(
      name: 'JioHotstar',
      serviceKey: 'JIOHOTSTAR',
      suggestedAmountInMinorUnits: 29900,
      billingCycle: ManualSubscriptionBillingCycle.monthly,
    ),
    PopularServiceEntry(
      name: 'Google One',
      serviceKey: 'GOOGLE_ONE',
      suggestedAmountInMinorUnits: 13000,
    ),
    PopularServiceEntry(
      name: 'ChatGPT Plus',
      serviceKey: 'CHATGPT',
      suggestedAmountInMinorUnits: 200000,
    ),
    PopularServiceEntry(
      name: 'Adobe Creative Cloud',
      serviceKey: 'ADOBE_SYSTEMS',
      suggestedAmountInMinorUnits: 167600,
    ),
    PopularServiceEntry(
      name: 'Canva Pro',
      serviceKey: 'CANVA',
      suggestedAmountInMinorUnits: 50000,
      billingCycle: ManualSubscriptionBillingCycle.yearly,
      planLabel: 'Pro',
    ),
    PopularServiceEntry(
      name: 'Apple One',
      serviceKey: 'APPLE_SERVICES',
      suggestedAmountInMinorUnits: 19500,
    ),
    PopularServiceEntry(
      name: 'Swiggy One',
      serviceKey: 'SWIGGY_ONE',
      suggestedAmountInMinorUnits: 9900,
      billingCycle: ManualSubscriptionBillingCycle.monthly,
    ),
    PopularServiceEntry(
      name: 'Zomato Gold',
      serviceKey: 'ZOMATO_GOLD',
      suggestedAmountInMinorUnits: 30000,
      billingCycle: ManualSubscriptionBillingCycle.monthly,
    ),
    PopularServiceEntry(
      name: 'SonyLIV',
      serviceKey: 'SONYLIV',
      suggestedAmountInMinorUnits: 29900,
      billingCycle: ManualSubscriptionBillingCycle.monthly,
    ),
    PopularServiceEntry(
      name: 'Zee5',
      serviceKey: 'ZEE5',
      suggestedAmountInMinorUnits: 14900,
      billingCycle: ManualSubscriptionBillingCycle.monthly,
    ),
    PopularServiceEntry(
      name: 'iCloud+',
      serviceKey: 'APPLE_SERVICES',
      suggestedAmountInMinorUnits: 7500,
      planLabel: '50 GB',
    ),
  ];

  /// Returns entries whose name contains [query], case-insensitive.
  /// Returns all entries when [query] is empty.
  static List<PopularServiceEntry> search(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return entries;
    }
    return entries
        .where(
          (entry) => entry.name.toLowerCase().contains(trimmed),
        )
        .toList(growable: false);
  }
}
