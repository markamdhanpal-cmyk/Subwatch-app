import '../contracts/review_action_store.dart';
import '../models/review_item_action_models.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';
import '../../domain/enums/dashboard_bucket.dart';
import '../../domain/enums/resolver_state.dart';
import '../../domain/value_objects/service_key.dart';

class AppliedReviewActionsResult {
  const AppliedReviewActionsResult({
    required this.cards,
    required this.reviewQueue,
    required this.confirmedReviewItems,
    required this.benefitReviewItems,
    required this.dismissedReviewItems,
  });

  final List<DashboardCard> cards;
  final List<ReviewItem> reviewQueue;
  final List<UserConfirmedReviewItem> confirmedReviewItems;
  final List<UserBenefitReviewItem> benefitReviewItems;
  final List<UserDismissedReviewItem> dismissedReviewItems;
}

class ApplyReviewItemActionsUseCase {
  const ApplyReviewItemActionsUseCase({
    required ReviewActionStore reviewActionStore,
  }) : _reviewActionStore = reviewActionStore;

  final ReviewActionStore _reviewActionStore;

  Future<AppliedReviewActionsResult> execute({
    required List<DashboardCard> cards,
    required List<ReviewItem> reviewQueue,
  }) async {
    final decisions = await _reviewActionStore.list();
    if (decisions.isEmpty) {
      return AppliedReviewActionsResult(
        cards: cards,
        reviewQueue: reviewQueue,
        confirmedReviewItems: const <UserConfirmedReviewItem>[],
        benefitReviewItems: const <UserBenefitReviewItem>[],
        dismissedReviewItems: const <UserDismissedReviewItem>[],
      );
    }

    final decisionsByTargetKey = <String, ReviewItemDecision>{
      for (final decision in decisions) decision.targetKey: decision,
    };
    final filteredReviewQueue = <ReviewItem>[];
    final confirmedReviewItems = <UserConfirmedReviewItem>[];
    final benefitReviewItems = <UserBenefitReviewItem>[];
    final dismissedReviewItems = <UserDismissedReviewItem>[];
    final actionedServiceKeys = <String>{};
    final promotedBenefitCards = <DashboardCard>[];

    for (final item in reviewQueue) {
      final descriptor = ReviewItemActionDescriptor.fromReviewItem(item);
      final decision = decisionsByTargetKey[descriptor.targetKey];
      if (decision == null) {
        filteredReviewQueue.add(item);
        continue;
      }

      if (decision.serviceKey !=
          ReviewItemActionDescriptor.unresolvedServiceKeyValue) {
        actionedServiceKeys.add(decision.serviceKey);
      }

      if (decision.action == ReviewItemAction.confirmSubscription &&
          descriptor.canConfirm) {
        confirmedReviewItems.add(
          UserConfirmedReviewItem(
            targetKey: decision.targetKey,
            serviceKey: ServiceKey(decision.serviceKey),
            title: decision.title,
            subtitle: 'Confirmed by your review',
          ),
        );
      } else if (decision.action == ReviewItemAction.markAsBenefit &&
          descriptor.canConfirm) {
        benefitReviewItems.add(
          UserBenefitReviewItem(
            targetKey: decision.targetKey,
            serviceKey: ServiceKey(decision.serviceKey),
            title: decision.title,
            subtitle: 'Marked as a benefit by your review',
          ),
        );
        promotedBenefitCards.add(
          DashboardCard(
            serviceKey: ServiceKey(decision.serviceKey),
            bucket: DashboardBucket.trialsAndBenefits,
            title: decision.title,
            subtitle: 'Kept separate as a benefit by your review',
            state: ResolverState.activeBundled,
          ),
        );
      } else if (decision.action == ReviewItemAction.dismissNotSubscription) {
        dismissedReviewItems.add(
          UserDismissedReviewItem(
            targetKey: decision.targetKey,
            title: decision.title,
            subtitle: 'Hidden by your review',
          ),
        );
      }
    }

    final filteredCards = cards.where((card) {
      if (card.bucket != DashboardBucket.needsReview) {
        return true;
      }

      return !actionedServiceKeys.contains(card.serviceKey.value);
    }).toList(growable: true)
      ..addAll(promotedBenefitCards);

    confirmedReviewItems.sort(
      (left, right) => left.serviceKey.value.compareTo(right.serviceKey.value),
    );
    benefitReviewItems.sort(
      (left, right) => left.serviceKey.value.compareTo(right.serviceKey.value),
    );
    dismissedReviewItems.sort(
      (left, right) => left.title.compareTo(right.title),
    );

    return AppliedReviewActionsResult(
      cards: filteredCards,
      reviewQueue: filteredReviewQueue,
      confirmedReviewItems: confirmedReviewItems,
      benefitReviewItems: benefitReviewItems,
      dismissedReviewItems: dismissedReviewItems,
    );
  }
}
