import '../models/dashboard_renewal_reminder_presentation.dart';
import '../models/dashboard_upcoming_renewals_presentation.dart';
import '../models/local_renewal_reminder_models.dart';

class BuildDashboardRenewalReminderItemsUseCase {
  const BuildDashboardRenewalReminderItemsUseCase({
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  List<DashboardRenewalReminderItemPresentation> execute({
    required DashboardUpcomingRenewalsPresentation upcomingRenewals,
    required Map<String, LocalRenewalReminderPreference> preferencesByServiceKey,
    DateTime? now,
  }) {
    final effectiveNow = now ?? _clock();
    return upcomingRenewals.items
        .map(
          (item) {
            final availablePresets = RenewalReminderLeadTimePreset.values
                .where((preset) =>
                    preset.scheduledAt(item.renewalDate).isAfter(effectiveNow))
                .toList(growable: false);
            final selectedPreset =
                preferencesByServiceKey[item.serviceKey]?.leadTimePreset;
            final canConfigureReminder =
                availablePresets.isNotEmpty || selectedPreset != null;
            final isEnabled = selectedPreset != null &&
                availablePresets.contains(selectedPreset);
            final statusLabel = _statusLabel(
              availablePresets: availablePresets,
              selectedPreset: selectedPreset,
              isEnabled: isEnabled,
            );

            return DashboardRenewalReminderItemPresentation(
              renewal: item,
              availablePresets: availablePresets,
              selectedPreset: selectedPreset,
              statusLabel: statusLabel,
              canConfigureReminder: canConfigureReminder,
            );
          },
        )
        .toList(growable: false);
  }

  String _statusLabel({
    required List<RenewalReminderLeadTimePreset> availablePresets,
    required RenewalReminderLeadTimePreset? selectedPreset,
    required bool isEnabled,
  }) {
    if (isEnabled && selectedPreset != null) {
      return 'Reminder on: ${selectedPreset.label}';
    }
    if (selectedPreset != null) {
      return 'Reminder not scheduled for this cycle';
    }
    if (availablePresets.isEmpty) {
      return 'Reminder unavailable for this renewal';
    }
    return 'Reminder off';
  }
}
