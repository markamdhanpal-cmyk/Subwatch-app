import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/review_item_action_models.dart';
import 'package:sub_killer/application/stores/in_memory_review_action_store.dart';
import 'package:sub_killer/application/use_cases/handle_review_item_action_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/undo_review_item_action_use_case.dart';

void main() {
  group('UndoReviewItemActionUseCase', () {
    test('undo restores an identified confirmed review item safely', () async {
      final reviewActionStore = InMemoryReviewActionStore();
      final initialSnapshot = await LoadRuntimeDashboardUseCase(
        reviewActionStore: reviewActionStore,
      ).execute();
      final reviewItem = initialSnapshot.reviewQueue.firstWhere(
        (item) => item.serviceKey.value == 'JIOHOTSTAR',
      );
      final targetKey =
          ReviewItemActionDescriptor.fromReviewItem(reviewItem).targetKey;

      final handleUseCase = HandleReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );
      await handleUseCase.execute(
        reviewItem: reviewItem,
        action: ReviewItemAction.confirmSubscription,
      );

      final undoUseCase = UndoReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );

      final result = await undoUseCase.execute(targetKey: targetKey);

      expect(result.outcome, ReviewItemUndoOutcome.restored);
      expect(result.snapshot, isNotNull);
      expect(
        result.snapshot!.reviewQueue.map((item) => item.serviceKey.value),
        contains('JIOHOTSTAR'),
      );
      expect(result.snapshot!.confirmedReviewItems, isEmpty);
    });

    test('undo restores a benefit-marked review item safely', () async {
      final reviewActionStore = InMemoryReviewActionStore();
      final initialSnapshot = await LoadRuntimeDashboardUseCase(
        reviewActionStore: reviewActionStore,
      ).execute();
      final reviewItem = initialSnapshot.reviewQueue.firstWhere(
        (item) => item.serviceKey.value == 'JIOHOTSTAR',
      );
      final targetKey =
          ReviewItemActionDescriptor.fromReviewItem(reviewItem).targetKey;

      final handleUseCase = HandleReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );
      await handleUseCase.execute(
        reviewItem: reviewItem,
        action: ReviewItemAction.markAsBenefit,
      );

      final undoUseCase = UndoReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );

      final result = await undoUseCase.execute(targetKey: targetKey);

      expect(result.outcome, ReviewItemUndoOutcome.restored);
      expect(result.snapshot, isNotNull);
      expect(
        result.snapshot!.reviewQueue.map((item) => item.serviceKey.value),
        contains('JIOHOTSTAR'),
      );
      expect(result.snapshot!.benefitReviewItems, isEmpty);
    });

    test('undo restores a dismissed unresolved review item safely', () async {
      final reviewActionStore = InMemoryReviewActionStore();
      final initialSnapshot = await LoadRuntimeDashboardUseCase(
        reviewActionStore: reviewActionStore,
      ).execute();
      final reviewItem = initialSnapshot.reviewQueue.firstWhere(
        (item) => item.serviceKey.value == 'UNRESOLVED',
      );
      final targetKey =
          ReviewItemActionDescriptor.fromReviewItem(reviewItem).targetKey;

      final handleUseCase = HandleReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );
      await handleUseCase.execute(
        reviewItem: reviewItem,
        action: ReviewItemAction.dismissNotSubscription,
      );

      final undoUseCase = UndoReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );

      final result = await undoUseCase.execute(targetKey: targetKey);

      expect(result.outcome, ReviewItemUndoOutcome.restored);
      expect(result.snapshot, isNotNull);
      expect(
        result.snapshot!.reviewQueue.map((item) => item.serviceKey.value),
        contains('UNRESOLVED'),
      );
      expect(result.snapshot!.dismissedReviewItems, isEmpty);
    });

    test('undo returns not found when no persisted decision exists', () async {
      final undoUseCase = UndoReviewItemActionUseCase(
        reviewActionStore: InMemoryReviewActionStore(),
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase().execute(),
      );

      final result = await undoUseCase.execute(targetKey: 'missing');

      expect(result.outcome, ReviewItemUndoOutcome.notFound);
      expect(result.snapshot, isNull);
    });
  });
}
