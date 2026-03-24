import '../models/local_renewal_reminder_models.dart';

abstract interface class LocalRenewalReminderStore {
  Future<List<LocalRenewalReminderPreference>> list();

  Future<void> save(LocalRenewalReminderPreference preference);

  Future<bool> remove(String serviceKey);

  Future<void> clear();
}
