import '../models/dashboard_upcoming_renewals_presentation.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/enums/dashboard_bucket.dart';
import '../../domain/enums/resolver_state.dart';
import '../models/manual_subscription_models.dart';

class BuildDashboardUpcomingRenewalsUseCase {
  const BuildDashboardUpcomingRenewalsUseCase({
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static final RegExp _renewalPattern = RegExp(
    r'\bRenews on ([0-9]{1,2}) ([A-Z][a-z]{2}) ([0-9]{4})\b',
  );
  static final RegExp _rupeeAmountPattern = RegExp(
    r'\bRs\s+([0-9]+(?:,[0-9]{3})*(?:\.[0-9]+)?)\b',
    caseSensitive: false,
  );

  final DateTime Function() _clock;

  DashboardUpcomingRenewalsPresentation execute({
    required List<DashboardCard> cards,
    List<ManualSubscriptionEntry>? manualSubscriptions,
    DateTime? now,
  }) {
    final startOfToday = _startOfDay(now ?? _clock());
    final cardItems = cards
        .where(
          (card) =>
              card.bucket == DashboardBucket.confirmedSubscriptions &&
              card.state == ResolverState.activePaid,
        )
        .map(_toItem)
        .whereType<DashboardUpcomingRenewalItemPresentation>();

    final manualItems = (manualSubscriptions ?? const <ManualSubscriptionEntry>[])
        .where((entry) => entry.hasNextRenewalDate)
        .map(_fromManualEntry);

    final items = [...cardItems, ...manualItems]
        .where((item) => !item.renewalDate.isBefore(startOfToday))
        .toList(growable: false)
      ..sort((left, right) => left.renewalDate.compareTo(right.renewalDate));

    return DashboardUpcomingRenewalsPresentation(
      items: List<DashboardUpcomingRenewalItemPresentation>.unmodifiable(items),
    );
  }

  DashboardUpcomingRenewalItemPresentation _fromManualEntry(
    ManualSubscriptionEntry entry,
  ) {
    return DashboardUpcomingRenewalItemPresentation(
      serviceKey: entry.id,
      serviceTitle: entry.serviceName,
      renewalDate: entry.nextRenewalDate!,
      renewalDateLabel: _formatRenewalDate(entry.nextRenewalDate!),
      amountLabel: _formatManualSubscriptionAmount(entry.amountInMinorUnits),
    );
  }

  String? _formatManualSubscriptionAmount(int? amountInMinorUnits) {
    if (amountInMinorUnits == null) {
      return null;
    }
    final wholeUnits = amountInMinorUnits ~/ 100;
    return 'Rs $wholeUnits';
  }

  DashboardUpcomingRenewalItemPresentation? _toItem(DashboardCard card) {
    final renewalDate = _extractRenewalDate(card.subtitle);
    if (renewalDate == null) {
      return null;
    }

    return DashboardUpcomingRenewalItemPresentation(
      serviceKey: card.serviceKey.value,
      serviceTitle: card.title,
      renewalDate: renewalDate,
      renewalDateLabel: _formatRenewalDate(renewalDate),
      amountLabel: card.amountLabel ?? _extractAmountLabel(card.subtitle),
    );
  }

  DateTime? _extractRenewalDate(String subtitle) {
    final match = _renewalPattern.firstMatch(subtitle);
    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1)!);
    final month = _monthIndex(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  String? _extractAmountLabel(String subtitle) {
    final match = _rupeeAmountPattern.firstMatch(subtitle);
    if (match == null) {
      return null;
    }

    return 'Rs ${match.group(1)!}';
  }

  int? _monthIndex(String month) {
    const months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    return months[month];
  }

  DateTime _startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  String _formatRenewalDate(DateTime renewalDate) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${renewalDate.day} ${months[renewalDate.month - 1]} ${renewalDate.year}';
  }
}
