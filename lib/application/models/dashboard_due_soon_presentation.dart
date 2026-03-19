import 'dashboard_upcoming_renewals_presentation.dart';

class DashboardDueSoonPresentation {
  const DashboardDueSoonPresentation({
    required this.items,
    required this.windowInDays,
  });

  final List<DashboardUpcomingRenewalItemPresentation> items;
  final int windowInDays;

  bool get hasItems => items.isNotEmpty;

  String get summaryCopy => hasItems
      ? 'Renewals due soon.'
      : 'Nothing due in the next $windowInDays days.';

  String get emptyTitle => 'Nothing due soon';

  String get emptyMessage => 'Only clear renewal dates appear here.';
}


