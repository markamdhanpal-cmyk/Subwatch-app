import '../models/runtime_snapshot_provenance.dart';
import '../../domain/entities/service_ledger_entry.dart';

abstract interface class LedgerSnapshotStore {
  Future<bool> hasSnapshot();

  Future<LedgerSnapshotRecord?> loadRecord();

  Future<void> saveRecord(LedgerSnapshotRecord record);

  Future<List<ServiceLedgerEntry>> load();

  Future<void> save(List<ServiceLedgerEntry> entries);

  Future<void> clear();
}
