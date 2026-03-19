import '../../domain/contracts/ledger_repository.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/value_objects/service_key.dart';

class InMemoryLedgerRepository implements LedgerRepository {
  final Map<String, ServiceLedgerEntry> _entriesByKey =
      <String, ServiceLedgerEntry>{};

  @override
  Future<ServiceLedgerEntry?> read(ServiceKey serviceKey) async {
    return _entriesByKey[serviceKey.value];
  }

  @override
  Future<void> write(ServiceLedgerEntry entry) async {
    _entriesByKey[entry.serviceKey.value] = entry;
  }

  @override
  Future<List<ServiceLedgerEntry>> list() async {
    final entries = _entriesByKey.values.toList(growable: false)
      ..sort(
        (left, right) => left.serviceKey.value.compareTo(right.serviceKey.value),
      );
    return entries;
  }

  Future<void> replaceAll(Iterable<ServiceLedgerEntry> entries) async {
    _entriesByKey
      ..clear()
      ..addEntries(
        entries.map(
          (entry) => MapEntry(entry.serviceKey.value, entry),
        ),
      );
  }
}
