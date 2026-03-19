enum RenewalReminderLeadTimePreset {
  oneDay,
  threeDays,
  sevenDays,
}

extension RenewalReminderLeadTimePresetX on RenewalReminderLeadTimePreset {
  int get daysBeforeRenewal {
    switch (this) {
      case RenewalReminderLeadTimePreset.oneDay:
        return 1;
      case RenewalReminderLeadTimePreset.threeDays:
        return 3;
      case RenewalReminderLeadTimePreset.sevenDays:
        return 7;
    }
  }

  String get label {
    switch (this) {
      case RenewalReminderLeadTimePreset.oneDay:
        return '1 day before';
      case RenewalReminderLeadTimePreset.threeDays:
        return '3 days before';
      case RenewalReminderLeadTimePreset.sevenDays:
        return '7 days before';
    }
  }

  DateTime scheduledAt(DateTime renewalDate) {
    final renewalDay =
        DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
    final reminderDay = renewalDay.subtract(Duration(days: daysBeforeRenewal));
    return DateTime(
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      9,
    );
  }

  static RenewalReminderLeadTimePreset? fromName(String? rawValue) {
    switch (rawValue) {
      case 'oneDay':
        return RenewalReminderLeadTimePreset.oneDay;
      case 'threeDays':
        return RenewalReminderLeadTimePreset.threeDays;
      case 'sevenDays':
        return RenewalReminderLeadTimePreset.sevenDays;
      default:
        return null;
    }
  }
}

class LocalRenewalReminderPreference {
  const LocalRenewalReminderPreference({
    required this.serviceKey,
    required this.leadTimePreset,
  });

  factory LocalRenewalReminderPreference.fromJson(Map<String, Object?> json) {
    return LocalRenewalReminderPreference(
      serviceKey: json['serviceKey'] as String? ?? '',
      leadTimePreset: RenewalReminderLeadTimePresetX.fromName(
            json['leadTimePreset'] as String?,
          ) ??
          RenewalReminderLeadTimePreset.oneDay,
    );
  }

  final String serviceKey;
  final RenewalReminderLeadTimePreset leadTimePreset;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'serviceKey': serviceKey,
      'leadTimePreset': leadTimePreset.name,
    };
  }
}

class LocalRenewalReminderScheduleRequest {
  const LocalRenewalReminderScheduleRequest({
    required this.serviceKey,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  final String serviceKey;
  final String title;
  final String body;
  final DateTime scheduledAt;
}
