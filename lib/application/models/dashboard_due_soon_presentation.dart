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
      return 'Nothing due soon.';
    }

    final count = items.length;
    return count == 1 ? '1 renewal due soon.' : '$count renewals due soon.';
  }

  String get emptyTitle => 'Nothing due soon';

  String get emptyMessage =>
      'Items with clear dates show up here.';
}


