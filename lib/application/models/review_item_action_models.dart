import '../../domain/entities/review_item.dart';
import '../../domain/value_objects/service_key.dart';

enum ReviewItemAction {
  confirmSubscription,
  markAsBenefit,
  dismissNotSubscription,
}

enum ReviewItemActionOutcome {
  confirmed,
  markedAsBenefit,
  dismissed,
  notAllowed,
}

enum ReviewItemUndoOutcome {
  restored,
  notFound,
}

class ReviewItemActionDescriptor {
  const ReviewItemActionDescriptor({
    required this.targetKey,
    required this.serviceKey,
    required this.canConfirm,
  });

  factory ReviewItemActionDescriptor.fromReviewItem(ReviewItem reviewItem) {
    final serviceKey = reviewItem.serviceKey.value;
    final sortedMessageIds =
        reviewItem.evidenceTrail.messageIds.toList(growable: false)..sort();
    final targetKey = serviceKey == unresolvedServiceKeyValue
        ? '$serviceKey::${sortedMessageIds.join('|')}'
        : serviceKey;

    return ReviewItemActionDescriptor(
      targetKey: targetKey,
      serviceKey: serviceKey,
      canConfirm: serviceKey != unresolvedServiceKeyValue,
    );
  }

  static const String unresolvedServiceKeyValue = 'UNRESOLVED';

  final String targetKey;
  final String serviceKey;
  final bool canConfirm;
}

class ReviewItemDecision {
  const ReviewItemDecision({
    required this.targetKey,
    required this.serviceKey,
    required this.title,
    required this.action,
    required this.decidedAt,
  });

  factory ReviewItemDecision.fromReviewItem({
    required ReviewItem reviewItem,
    required ReviewItemAction action,
    required DateTime decidedAt,
  }) {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(reviewItem);
    return ReviewItemDecision(
      targetKey: descriptor.targetKey,
      serviceKey: descriptor.serviceKey,
      title: reviewItem.title,
      action: action,
      decidedAt: decidedAt,
    );
  }

  factory ReviewItemDecision.fromJson(Map<String, Object?> json) {
    return ReviewItemDecision(
      targetKey: json['targetKey'] as String,
      serviceKey: json['serviceKey'] as String,
      title: json['title'] as String,
      action: ReviewItemAction.values.firstWhere(
        (value) => value.name == json['action'],
      ),
      decidedAt: DateTime.parse(json['decidedAt'] as String),
    );
  }

  final String targetKey;
  final String serviceKey;
  final String title;
  final ReviewItemAction action;
  final DateTime decidedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'targetKey': targetKey,
      'serviceKey': serviceKey,
      'title': title,
      'action': action.name,
      'decidedAt': decidedAt.toIso8601String(),
    };
  }
}

class UserConfirmedReviewItem {
  const UserConfirmedReviewItem({
    required this.targetKey,
    required this.serviceKey,
    required this.title,
    required this.subtitle,
  });

  final String targetKey;
  final ServiceKey serviceKey;
  final String title;
  final String subtitle;
}

class UserDismissedReviewItem {
  const UserDismissedReviewItem({
    required this.targetKey,
    required this.title,
    required this.subtitle,
  });

  final String targetKey;
  final String title;
  final String subtitle;
}

class UserBenefitReviewItem {
  const UserBenefitReviewItem({
    required this.targetKey,
    required this.serviceKey,
    required this.title,
    required this.subtitle,
  });

  final String targetKey;
  final ServiceKey serviceKey;
  final String title;
  final String subtitle;
}
