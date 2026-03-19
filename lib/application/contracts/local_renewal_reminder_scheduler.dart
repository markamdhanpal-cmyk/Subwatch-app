import '../models/local_renewal_reminder_models.dart';

abstract interface class LocalRenewalReminderScheduler {
  Future<bool> schedule(LocalRenewalReminderScheduleRequest request);

  Future<bool> cancel(String serviceKey);
}
