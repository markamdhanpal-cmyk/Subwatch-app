import '../entities/service_ledger_entry.dart';
import '../value_objects/service_key.dart';

abstract interface class LedgerRepository {
  Future<ServiceLedgerEntry?> read(ServiceKey serviceKey);

  Future<void> write(ServiceLedgerEntry entry);

  Future<List<ServiceLedgerEntry>> list();
}
