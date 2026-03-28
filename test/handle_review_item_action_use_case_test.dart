import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/review_item_action_models.dart';
import 'package:sub_killer/application/stores/in_memory_review_action_store.dart';
import 'package:sub_killer/application/use_cases/handle_review_item_action_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';

void main() {
  group('HandleReviewItemActionUseCase', () {
    test(
        'confirming an identified review item removes it from review and adds it to confirmed by you',
        () async {
      final reviewActionStore = InMemoryReviewActionStore();
      final initialSnapshot = await LoadRuntimeDashboardUseCase(
        reviewActionStore: reviewActionStore,
      ).execute();
      final reviewItem = initialSnapshot.reviewQueue.firstWhere(
        (item) => item.serviceKey.value == 'JIOHOTSTAR',
      );

      final useCase = HandleReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
        clock: () => DateTime(2026, 3, 13, 11, 0),
      );

      final result = await useCase.execute(
        reviewItem: reviewItem,
        action: ReviewItemAction.confirmSubscription,
      );

      expect(result.outcome, ReviewItemActionOutcome.confirmed);
      expect(result.snapshot, isNotNull);
      expect(
        result.snapshot!.reviewQueue.map((item) => item.serviceKey.value),
        isNot(contains('JIOHOTSTAR')),
      );
      expect(
        result.snapshot!.confirmedReviewItems
            .map((item) => item.serviceKey.value),
        contains('JIOHOTSTAR'),
      );
      expect(
        result.snapshot!.cards
            .where((card) => card.bucket == DashboardBucket.needsReview)
            .map((card) => card.serviceKey.value),
        isNot(contains('JIOHOTSTAR')),
      );
    });

    test(
        'marking an identified review item as benefit removes it from review and keeps it separate',
        () async {
      final reviewActionStore = InMemoryReviewActionStore();
      final initialSnapshot = await LoadRuntimeDashboardUseCase(
        reviewActionStore: reviewActionStore,
      ).execute();
      final reviewItem = initialSnapshot.reviewQueue.firstWhere(
        (item) => item.serviceKey.value == 'JIOHOTSTAR',
      );

      final useCase = HandleReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );

      final result = await useCase.execute(
        reviewItem: reviewItem,
        action: ReviewItemAction.markAsBenefit,
      );

      expect(result.outcome, ReviewItemActionOutcome.markedAsBenefit);
      expect(result.snapshot, isNotNull);
      expect(
        result.snapshot!.reviewQueue.map((item) => item.serviceKey.value),
        isNot(contains('JIOHOTSTAR')),
      );
      expect(
        result.snapshot!.benefitReviewItems
            .map((item) => item.serviceKey.value),
        contains('JIOHOTSTAR'),
      );
      expect(
        result.snapshot!.cards
            .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
            .map((card) => card.serviceKey.value),
        contains('JIOHOTSTAR'),
      );
    });

    test(
        'dismissing an unresolved review item removes it from the review queue',
        () async {
      final reviewActionStore = InMemoryReviewActionStore();
      final initialSnapshot = await LoadRuntimeDashboardUseCase(
        reviewActionStore: reviewActionStore,
      ).execute();
      final reviewItem = initialSnapshot.reviewQueue.firstWhere(
        (item) => item.serviceKey.value == 'UNRESOLVED',
      );

      final useCase = HandleReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );

      final result = await useCase.execute(
        reviewItem: reviewItem,
        action: ReviewItemAction.dismissNotSubscription,
      );

      expect(result.outcome, ReviewItemActionOutcome.dismissed);
      expect(result.snapshot, isNotNull);
      expect(
        result.snapshot!.reviewQueue.map((item) => item.serviceKey.value),
        isNot(contains('UNRESOLVED')),
      );
      expect(result.snapshot!.confirmedReviewItems, isEmpty);
    });

    test('confirming an unresolved review item is rejected safely', () async {
      final reviewActionStore = InMemoryReviewActionStore();
      final initialSnapshot = await LoadRuntimeDashboardUseCase(
        reviewActionStore: reviewActionStore,
      ).execute();
      final reviewItem = initialSnapshot.reviewQueue.firstWhere(
        (item) => item.serviceKey.value == 'UNRESOLVED',
      );

      final useCase = HandleReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          reviewActionStore: reviewActionStore,
        ).execute(),
      );

      final result = await useCase.execute(
        reviewItem: reviewItem,
        action: ReviewItemAction.confirmSubscription,
      );

      expect(result.outcome, ReviewItemActionOutcome.notAllowed);
      expect(result.snapshot, isNull);
      expect(await reviewActionStore.list(), isEmpty);
    });
  });
}
