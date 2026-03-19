import '../contracts/ledger_snapshot_store.dart';
import '../contracts/local_control_overlay_store.dart';
import '../models/local_control_overlay_models.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_local_control_overlay_store.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';
import 'load_runtime_dashboard_use_case.dart';

class HandleLocalControlOverlayResult {
  const HandleLocalControlOverlayResult({
    required this.decision,
    this.snapshot,
  });

  final LocalControlDecision decision;
  final RuntimeDashboardSnapshot? snapshot;
}

class HandleLocalControlOverlayUseCase {
  factory HandleLocalControlOverlayUseCase.persistent({
    LedgerSnapshotStore? ledgerSnapshotStore,
    LocalControlOverlayStore? localControlOverlayStore,
    Future<RuntimeDashboardSnapshot> Function()? loadRuntimeDashboard,
    DateTime Function()? clock,
  }) {
    final resolvedLedgerSnapshotStore =
        ledgerSnapshotStore ?? JsonFileLedgerSnapshotStore.applicationSupport();
    final resolvedLocalControlOverlayStore = localControlOverlayStore ??
        JsonFileLocalControlOverlayStore.applicationSupport();

    return HandleLocalControlOverlayUseCase(
      localControlOverlayStore: resolvedLocalControlOverlayStore,
      loadRuntimeDashboard: loadRuntimeDashboard ??
          () => LoadRuntimeDashboardUseCase.persistent(
                ledgerSnapshotStore: resolvedLedgerSnapshotStore,
                localControlOverlayStore: resolvedLocalControlOverlayStore,
              ).execute(),
      clock: clock,
    );
  }

  HandleLocalControlOverlayUseCase({
    required LocalControlOverlayStore localControlOverlayStore,
    required Future<RuntimeDashboardSnapshot> Function() loadRuntimeDashboard,
    DateTime Function()? clock,
  })  : _localControlOverlayStore = localControlOverlayStore,
        _loadRuntimeDashboard = loadRuntimeDashboard,
        _clock = clock ?? DateTime.now;

  final LocalControlOverlayStore _localControlOverlayStore;
  final Future<RuntimeDashboardSnapshot> Function() _loadRuntimeDashboard;
  final DateTime Function() _clock;

  Future<HandleLocalControlOverlayResult> ignoreCard(
    DashboardCard card,
  ) async {
    final decision = LocalControlDecision.ignoreService(
      card: card,
      decidedAt: _clock(),
    );
    await _localControlOverlayStore.save(decision);
    return HandleLocalControlOverlayResult(
      decision: decision,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<HandleLocalControlOverlayResult> hideCard(
    DashboardCard card,
  ) async {
    final decision = LocalControlDecision.hideCard(
      card: card,
      decidedAt: _clock(),
    );
    await _localControlOverlayStore.save(decision);
    return HandleLocalControlOverlayResult(
      decision: decision,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<HandleLocalControlOverlayResult> ignoreReviewItem(
    ReviewItem item,
  ) async {
    final decision = LocalControlDecision.ignoreReviewItem(
      reviewItem: item,
      decidedAt: _clock(),
    );
    await _localControlOverlayStore.save(decision);
    return HandleLocalControlOverlayResult(
      decision: decision,
      snapshot: await _loadRuntimeDashboard(),
    );
  }
}
