import '../models/manual_subscription_models.dart';

abstract interface class LocalManualSubscriptionStore {
  Future<List<ManualSubscriptionEntry>> list();

  Future<void> save(ManualSubscriptionEntry entry);

  Future<bool> remove(String id);

  Future<void> clear();
}
