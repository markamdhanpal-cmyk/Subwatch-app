import '../contracts/ledger_snapshot_store.dart';
import '../contracts/review_action_store.dart';
import '../models/review_item_action_models.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_review_action_store.dart';
import 'load_runtime_dashboard_use_case.dart';

class UndoReviewItemActionResult {
  const UndoReviewItemActionResult({
    required this.outcome,
    this.snapshot,
  });

  final ReviewItemUndoOutcome outcome;
  final RuntimeDashboardSnapshot? snapshot;
}

class UndoReviewItemActionUseCase {
  factory UndoReviewItemActionUseCase.persistent({
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    Future<RuntimeDashboardSnapshot> Function()? loadRuntimeDashboard,
  }) {
    final resolvedLedgerSnapshotStore =
        ledgerSnapshotStore ?? JsonFileLedgerSnapshotStore.applicationSupport();
    final resolvedReviewActionStore =
        reviewActionStore ?? JsonFileReviewActionStore.applicationSupport();

    return UndoReviewItemActionUseCase(
      reviewActionStore: resolvedReviewActionStore,
      loadRuntimeDashboard: loadRuntimeDashboard ??
          () => LoadRuntimeDashboardUseCase.persistent(
                ledgerSnapshotStore: resolvedLedgerSnapshotStore,
                reviewActionStore: resolvedReviewActionStore,
              ).execute(),
    );
  }

  UndoReviewItemActionUseCase({
    required ReviewActionStore reviewActionStore,
    required Future<RuntimeDashboardSnapshot> Function() loadRuntimeDashboard,
  })  : _reviewActionStore = reviewActionStore,
        _loadRuntimeDashboard = loadRuntimeDashboard;

  final ReviewActionStore _reviewActionStore;
  final Future<RuntimeDashboardSnapshot> Function() _loadRuntimeDashboard;

  Future<UndoReviewItemActionResult> execute({
    required String targetKey,
  }) async {
    final removed = await _reviewActionStore.remove(targetKey);
    if (!removed) {
      return const UndoReviewItemActionResult(
        outcome: ReviewItemUndoOutcome.notFound,
      );
    }

    final snapshot = await _loadRuntimeDashboard();
    return UndoReviewItemActionResult(
      outcome: ReviewItemUndoOutcome.restored,
      snapshot: snapshot,
    );
  }
}
