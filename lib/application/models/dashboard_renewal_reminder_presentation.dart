import 'dashboard_upcoming_renewals_presentation.dart';
import 'local_renewal_reminder_models.dart';

class DashboardRenewalReminderItemPresentation {
  const DashboardRenewalReminderItemPresentation({
    required this.renewal,
    required this.availablePresets,
    required this.selectedPreset,
    required this.statusLabel,
    required this.canConfigureReminder,
  });

  final DashboardUpcomingRenewalItemPresentation renewal;
  final List<RenewalReminderLeadTimePreset> availablePresets;
  final RenewalReminderLeadTimePreset? selectedPreset;
  final String statusLabel;
  final bool canConfigureReminder;
}
