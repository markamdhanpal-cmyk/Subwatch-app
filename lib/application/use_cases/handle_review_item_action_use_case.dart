import '../contracts/ledger_snapshot_store.dart';
import '../contracts/review_action_store.dart';
import '../models/review_item_action_models.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_review_action_store.dart';
import '../../domain/entities/review_item.dart';
import 'load_runtime_dashboard_use_case.dart';

class HandleReviewItemActionResult {
  const HandleReviewItemActionResult({
    required this.outcome,
    this.snapshot,
  });

  final ReviewItemActionOutcome outcome;
  final RuntimeDashboardSnapshot? snapshot;
}

class HandleReviewItemActionUseCase {
  factory HandleReviewItemActionUseCase.persistent({
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    Future<RuntimeDashboardSnapshot> Function()? loadRuntimeDashboard,
    DateTime Function()? clock,
  }) {
    final resolvedLedgerSnapshotStore =
        ledgerSnapshotStore ?? JsonFileLedgerSnapshotStore.applicationSupport();
    final resolvedReviewActionStore =
        reviewActionStore ?? JsonFileReviewActionStore.applicationSupport();

    return HandleReviewItemActionUseCase(
      reviewActionStore: resolvedReviewActionStore,
      loadRuntimeDashboard: loadRuntimeDashboard ??
          () => LoadRuntimeDashboardUseCase.persistent(
                ledgerSnapshotStore: resolvedLedgerSnapshotStore,
                reviewActionStore: resolvedReviewActionStore,
              ).execute(),
      clock: clock,
    );
  }

  HandleReviewItemActionUseCase({
    required ReviewActionStore reviewActionStore,
    required Future<RuntimeDashboardSnapshot> Function() loadRuntimeDashboard,
    DateTime Function()? clock,
  })  : _reviewActionStore = reviewActionStore,
        _loadRuntimeDashboard = loadRuntimeDashboard,
        _clock = clock ?? DateTime.now;

  final ReviewActionStore _reviewActionStore;
  final Future<RuntimeDashboardSnapshot> Function() _loadRuntimeDashboard;
  final DateTime Function() _clock;

  Future<HandleReviewItemActionResult> execute({
    required ReviewItem reviewItem,
    required ReviewItemAction action,
  }) async {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(reviewItem);
    if (action == ReviewItemAction.confirmSubscription &&
        !descriptor.canConfirm) {
      return const HandleReviewItemActionResult(
        outcome: ReviewItemActionOutcome.notAllowed,
      );
    }

    await _reviewActionStore.save(
      ReviewItemDecision.fromReviewItem(
        reviewItem: reviewItem,
        action: action,
        decidedAt: _clock(),
      ),
    );

    final snapshot = await _loadRuntimeDashboard();
    return HandleReviewItemActionResult(
      outcome: switch (action) {
        ReviewItemAction.confirmSubscription =>
          ReviewItemActionOutcome.confirmed,
        ReviewItemAction.markAsBenefit =>
          ReviewItemActionOutcome.markedAsBenefit,
        ReviewItemAction.dismissNotSubscription =>
          ReviewItemActionOutcome.dismissed,
      },
      snapshot: snapshot,
    );
  }
}
