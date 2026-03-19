import '../contracts/local_manual_subscription_store.dart';
import '../models/manual_subscription_models.dart';

class InMemoryLocalManualSubscriptionStore
    implements LocalManualSubscriptionStore {
  final Map<String, ManualSubscriptionEntry> _entries =
      <String, ManualSubscriptionEntry>{};

  @override
  Future<List<ManualSubscriptionEntry>> list() async {
    final entries = _entries.values.toList(growable: false)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return entries;
  }

  @override
  Future<void> save(ManualSubscriptionEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<bool> remove(String id) async {
    return _entries.remove(id) != null;
  }
}
