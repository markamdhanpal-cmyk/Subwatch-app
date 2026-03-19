import '../contracts/ledger_snapshot_store.dart';
import '../contracts/local_control_overlay_store.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_local_control_overlay_store.dart';
import 'load_runtime_dashboard_use_case.dart';

enum LocalControlUndoOutcome {
  restored,
  notFound,
}

class UndoLocalControlOverlayResult {
  const UndoLocalControlOverlayResult({
    required this.outcome,
    this.snapshot,
  });

  final LocalControlUndoOutcome outcome;
  final RuntimeDashboardSnapshot? snapshot;
}

class UndoLocalControlOverlayUseCase {
  factory UndoLocalControlOverlayUseCase.persistent({
    LedgerSnapshotStore? ledgerSnapshotStore,
    LocalControlOverlayStore? localControlOverlayStore,
    Future<RuntimeDashboardSnapshot> Function()? loadRuntimeDashboard,
  }) {
    final resolvedLedgerSnapshotStore =
        ledgerSnapshotStore ?? JsonFileLedgerSnapshotStore.applicationSupport();
    final resolvedLocalControlOverlayStore = localControlOverlayStore ??
        JsonFileLocalControlOverlayStore.applicationSupport();

    return UndoLocalControlOverlayUseCase(
      localControlOverlayStore: resolvedLocalControlOverlayStore,
      loadRuntimeDashboard: loadRuntimeDashboard ??
          () => LoadRuntimeDashboardUseCase.persistent(
                ledgerSnapshotStore: resolvedLedgerSnapshotStore,
                localControlOverlayStore: resolvedLocalControlOverlayStore,
              ).execute(),
    );
  }

  UndoLocalControlOverlayUseCase({
    required LocalControlOverlayStore localControlOverlayStore,
    required Future<RuntimeDashboardSnapshot> Function() loadRuntimeDashboard,
  })  : _localControlOverlayStore = localControlOverlayStore,
        _loadRuntimeDashboard = loadRuntimeDashboard;

  final LocalControlOverlayStore _localControlOverlayStore;
  final Future<RuntimeDashboardSnapshot> Function() _loadRuntimeDashboard;

  Future<UndoLocalControlOverlayResult> execute({
    required String targetKey,
  }) async {
    final removed = await _localControlOverlayStore.remove(targetKey);
    if (!removed) {
      return const UndoLocalControlOverlayResult(
        outcome: LocalControlUndoOutcome.notFound,
      );
    }

    return UndoLocalControlOverlayResult(
      outcome: LocalControlUndoOutcome.restored,
      snapshot: await _loadRuntimeDashboard(),
    );
  }
}
