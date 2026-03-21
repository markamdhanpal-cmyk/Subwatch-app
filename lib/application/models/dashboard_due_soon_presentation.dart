import 'dashboard_upcoming_renewals_presentation.dart';

class DashboardDueSoonPresentation {
  const DashboardDueSoonPresentation({
    required this.items,
    required this.windowInDays,
  });

  final List<DashboardUpcomingRenewalItemPresentation> items;
  final int windowInDays;

  bool get hasItems => items.isNotEmpty;

  String get summaryCopy {
    if (!hasItems) {
      return 'Nothing due in the next $windowInDays days.';
    }

    final count = items.length;
    final renewalLabel = count == 1 ? 'renewal is' : 'renewals are';
    return '$count $renewalLabel due in the next $windowInDays days.';
  }

  String get emptyTitle => 'Nothing due soon';

  String get emptyMessage =>
      'Only confirmed subscriptions or manual entries with a clear renewal date appear here.';
}


