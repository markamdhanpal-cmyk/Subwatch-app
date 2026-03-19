import '../contracts/local_renewal_reminder_store.dart';
import '../models/local_renewal_reminder_models.dart';

class InMemoryLocalRenewalReminderStore
    implements LocalRenewalReminderStore {
  final Map<String, LocalRenewalReminderPreference> _preferencesByServiceKey =
      <String, LocalRenewalReminderPreference>{};

  @override
  Future<List<LocalRenewalReminderPreference>> list() async {
    final preferences = _preferencesByServiceKey.values.toList(growable: false)
      ..sort((left, right) => left.serviceKey.compareTo(right.serviceKey));
    return preferences;
  }

  @override
  Future<void> save(LocalRenewalReminderPreference preference) async {
    _preferencesByServiceKey[preference.serviceKey] = preference;
  }

  @override
  Future<bool> remove(String serviceKey) async {
    return _preferencesByServiceKey.remove(serviceKey) != null;
  }
}
