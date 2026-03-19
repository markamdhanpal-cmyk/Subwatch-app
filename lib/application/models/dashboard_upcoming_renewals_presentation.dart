class DashboardUpcomingRenewalItemPresentation {
  const DashboardUpcomingRenewalItemPresentation({
    required this.serviceKey,
    required this.serviceTitle,
    required this.renewalDate,
    required this.renewalDateLabel,
    this.amountLabel,
  });

  final String serviceKey;
  final String serviceTitle;
  final DateTime renewalDate;
  final String renewalDateLabel;
  final String? amountLabel;
}

class DashboardUpcomingRenewalsPresentation {
  const DashboardUpcomingRenewalsPresentation({
    required this.items,
  });

  final List<DashboardUpcomingRenewalItemPresentation> items;

  bool get hasItems => items.isNotEmpty;

  String get summaryCopy => hasItems
      ? 'Renewals with clear dates.'
      : 'No renewals yet.';

  String get emptyTitle => 'Nothing coming up';

  String get emptyMessage => 'Renewals appear here when a clear date is available.';
}

