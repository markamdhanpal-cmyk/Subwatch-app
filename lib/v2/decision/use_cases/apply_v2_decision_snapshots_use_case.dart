import '../../../domain/contracts/ledger_repository.dart';
import '../../../domain/contracts/service_evidence_bucket_repository.dart';
import '../bridges/decision_snapshot_ledger_bridge.dart';
import '../enums/decision_execution_mode.dart';
import '../models/decision_snapshot.dart';
import 'decision_engine_v2_use_case.dart';

class ApplyV2DecisionSnapshotsUseCase {
  const ApplyV2DecisionSnapshotsUseCase({
    DecisionEngineV2UseCase decisionEngine = const DecisionEngineV2UseCase(),
    DecisionSnapshotLedgerBridge ledgerBridge =
        const DecisionSnapshotLedgerBridge(),
  })  : _decisionEngine = decisionEngine,
        _ledgerBridge = ledgerBridge;

  final DecisionEngineV2UseCase _decisionEngine;
  final DecisionSnapshotLedgerBridge _ledgerBridge;

  Future<List<DecisionSnapshot>> execute({
    required ServiceEvidenceBucketRepository bucketRepository,
    required LedgerRepository ledgerRepository,
    DecisionExecutionMode mode = DecisionExecutionMode.bridgeToLedger,
  }) async {
    final snapshots = _decisionEngine.decideAll(await bucketRepository.list());
    if (mode == DecisionExecutionMode.shadowOnly) {
      return snapshots;
    }

    for (final snapshot in snapshots) {
      final currentEntry = await ledgerRepository.read(snapshot.serviceKey);
      await ledgerRepository.write(
        _ledgerBridge.map(
          snapshot: snapshot,
          currentEntry: currentEntry,
        ),
      );
    }

    return snapshots;
  }
}
