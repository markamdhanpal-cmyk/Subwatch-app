import '../contracts/local_control_overlay_store.dart';
import '../models/local_control_overlay_models.dart';
import '../models/review_item_action_models.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';

class AppliedLocalControlOverlaysResult {
  const AppliedLocalControlOverlaysResult({
    required this.cards,
    required this.reviewQueue,
    required this.ignoredItems,
    required this.hiddenItems,
    required this.confirmedReviewItems,
    required this.benefitReviewItems,
    required this.dismissedReviewItems,
  });

  final List<DashboardCard> cards;
  final List<ReviewItem> reviewQueue;
  final List<UserIgnoredLocalItem> ignoredItems;
  final List<UserHiddenLocalItem> hiddenItems;
  final List<UserConfirmedReviewItem> confirmedReviewItems;
  final List<UserBenefitReviewItem> benefitReviewItems;
  final List<UserDismissedReviewItem> dismissedReviewItems;
}

class ApplyLocalControlOverlaysUseCase {
  const ApplyLocalControlOverlaysUseCase({
    required LocalControlOverlayStore localControlOverlayStore,
  }) : _localControlOverlayStore = localControlOverlayStore;

  final LocalControlOverlayStore _localControlOverlayStore;

  Future<AppliedLocalControlOverlaysResult> execute({
    required List<DashboardCard> cards,
    required List<ReviewItem> reviewQueue,
    required List<UserConfirmedReviewItem> confirmedReviewItems,
    required List<UserBenefitReviewItem> benefitReviewItems,
    required List<UserDismissedReviewItem> dismissedReviewItems,
  }) async {
    final decisions = await _localControlOverlayStore.list();
    if (decisions.isEmpty) {
      return AppliedLocalControlOverlaysResult(
        cards: cards,
        reviewQueue: reviewQueue,
        ignoredItems: const <UserIgnoredLocalItem>[],
        hiddenItems: const <UserHiddenLocalItem>[],
        confirmedReviewItems: confirmedReviewItems,
        benefitReviewItems: benefitReviewItems,
        dismissedReviewItems: dismissedReviewItems,
      );
    }

    final ignoredServiceKeys = <String>{
      for (final decision in decisions)
        if (decision.actionKind == LocalControlActionKind.ignore &&
            decision.targetKind == LocalControlTargetKind.service)
          decision.serviceKey,
    };
    final ignoredReviewTargets = <String>{
      for (final decision in decisions)
        if (decision.actionKind == LocalControlActionKind.ignore &&
            decision.targetKind == LocalControlTargetKind.reviewItem)
          decision.targetKey.replaceFirst('review::', ''),
    };
    final hiddenCardTargets = <String>{
      for (final decision in decisions)
        if (decision.actionKind == LocalControlActionKind.hide &&
            decision.targetKind == LocalControlTargetKind.card)
          '${decision.bucketName}::${decision.serviceKey}',
    };

    final filteredCards = cards.where((card) {
      if (ignoredServiceKeys.contains(card.serviceKey.value)) {
        return false;
      }

      final cardTarget = '${card.bucket.name}::${card.serviceKey.value}';
      return !hiddenCardTargets.contains(cardTarget);
    }).toList(growable: false);

    final filteredReviewQueue = reviewQueue.where((item) {
      final descriptor = ReviewItemActionDescriptor.fromReviewItem(item);
      if (ignoredServiceKeys.contains(descriptor.serviceKey)) {
        return false;
      }

      return !ignoredReviewTargets.contains(descriptor.targetKey);
    }).toList(growable: false);

    final filteredConfirmedReviewItems = confirmedReviewItems
        .where((item) => !ignoredServiceKeys.contains(item.serviceKey.value))
        .toList(growable: false);
    final filteredBenefitReviewItems = benefitReviewItems
        .where((item) => !ignoredServiceKeys.contains(item.serviceKey.value))
        .toList(growable: false);

    final filteredDismissedReviewItems = dismissedReviewItems
        .where((item) => !ignoredReviewTargets.contains(item.targetKey))
        .toList(growable: false);

    final ignoredItems = decisions
        .where(
            (decision) => decision.actionKind == LocalControlActionKind.ignore)
        .map(
          (decision) => UserIgnoredLocalItem(
            targetKey: decision.targetKey,
            title: decision.title,
            subtitle: decision.targetKind == LocalControlTargetKind.service
                ? 'Ignored locally across the dashboard on this device'
                : 'Ignored locally in review on this device',
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.title.compareTo(right.title));

    final hiddenItems = decisions
        .where((decision) => decision.actionKind == LocalControlActionKind.hide)
        .map(
          (decision) => UserHiddenLocalItem(
            targetKey: decision.targetKey,
            title: decision.title,
            subtitle: _hiddenSubtitle(decision.bucketName),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.title.compareTo(right.title));

    return AppliedLocalControlOverlaysResult(
      cards: filteredCards,
      reviewQueue: filteredReviewQueue,
      ignoredItems: ignoredItems,
      hiddenItems: hiddenItems,
      confirmedReviewItems: filteredConfirmedReviewItems,
      benefitReviewItems: filteredBenefitReviewItems,
      dismissedReviewItems: filteredDismissedReviewItems,
    );
  }

  String _hiddenSubtitle(String? bucketName) {
    return switch (bucketName) {
      'confirmedSubscriptions' => 'Hidden locally from confirmed subscriptions',
      'needsReview' => 'Hidden locally from observed signals',
      'trialsAndBenefits' => 'Hidden locally from trials and benefits',
      _ => 'Hidden locally on this device',
    };
  }
}
