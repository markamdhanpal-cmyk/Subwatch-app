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

  String get summaryCopy {
    if (!hasItems) {
      return 'No renewal dates yet.';
    }

    final next = items.first;
    if (items.length == 1) {
      return '${next.serviceTitle} is next.';
    }

    final remaining = items.length - 1;
    return '${next.serviceTitle} is next. $remaining more follow.';
  }

  String get emptyTitle => 'No renewal dates yet';

  String get emptyMessage =>
      'Renewals appear here once dates are clear.';
}

