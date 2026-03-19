import '../models/dashboard_due_soon_presentation.dart';
import '../models/dashboard_upcoming_renewals_presentation.dart';

class BuildDashboardDueSoonUseCase {
  const BuildDashboardDueSoonUseCase({
    this.windowInDays = 7,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int windowInDays;
  final DateTime Function() _clock;

  DashboardDueSoonPresentation execute({
    required DashboardUpcomingRenewalsPresentation upcomingRenewals,
  }) {
    final startOfToday = _startOfDay(_clock());
    final endOfWindow = startOfToday.add(Duration(days: windowInDays));
    final items = upcomingRenewals.items
        .where((item) => !item.renewalDate.isBefore(startOfToday))
        .where((item) => !item.renewalDate.isAfter(endOfWindow))
        .toList(growable: false)
      ..sort((left, right) => left.renewalDate.compareTo(right.renewalDate));

    return DashboardDueSoonPresentation(
      items: List<DashboardUpcomingRenewalItemPresentation>.unmodifiable(items),
      windowInDays: windowInDays,
    );
  }

  DateTime _startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
