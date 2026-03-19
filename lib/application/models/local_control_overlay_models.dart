import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';
import '../models/review_item_action_models.dart';

enum LocalControlActionKind {
  ignore,
  hide,
}

enum LocalControlTargetKind {
  service,
  reviewItem,
  card,
}

class LocalControlDecision {
  const LocalControlDecision({
    required this.targetKey,
    required this.actionKind,
    required this.targetKind,
    required this.title,
    required this.serviceKey,
    required this.bucketName,
    required this.decidedAt,
  });

  factory LocalControlDecision.ignoreService({
    required DashboardCard card,
    required DateTime decidedAt,
  }) {
    return LocalControlDecision(
      targetKey: 'service::${card.serviceKey.value}',
      actionKind: LocalControlActionKind.ignore,
      targetKind: LocalControlTargetKind.service,
      title: card.title,
      serviceKey: card.serviceKey.value,
      bucketName: card.bucket.name,
      decidedAt: decidedAt,
    );
  }

  factory LocalControlDecision.hideCard({
    required DashboardCard card,
    required DateTime decidedAt,
  }) {
    return LocalControlDecision(
      targetKey: 'card::${card.bucket.name}::${card.serviceKey.value}',
      actionKind: LocalControlActionKind.hide,
      targetKind: LocalControlTargetKind.card,
      title: card.title,
      serviceKey: card.serviceKey.value,
      bucketName: card.bucket.name,
      decidedAt: decidedAt,
    );
  }

  factory LocalControlDecision.ignoreReviewItem({
    required ReviewItem reviewItem,
    required DateTime decidedAt,
  }) {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(reviewItem);
    if (descriptor.canConfirm) {
      return LocalControlDecision(
        targetKey: 'service::${descriptor.serviceKey}',
        actionKind: LocalControlActionKind.ignore,
        targetKind: LocalControlTargetKind.service,
        title: reviewItem.title,
        serviceKey: descriptor.serviceKey,
        bucketName: null,
        decidedAt: decidedAt,
      );
    }

    return LocalControlDecision(
      targetKey: 'review::${descriptor.targetKey}',
      actionKind: LocalControlActionKind.ignore,
      targetKind: LocalControlTargetKind.reviewItem,
      title: reviewItem.title,
      serviceKey: descriptor.serviceKey,
      bucketName: null,
      decidedAt: decidedAt,
    );
  }

  factory LocalControlDecision.fromJson(Map<String, Object?> json) {
    return LocalControlDecision(
      targetKey: json['targetKey'] as String,
      actionKind: LocalControlActionKind.values.firstWhere(
        (value) => value.name == json['actionKind'],
      ),
      targetKind: LocalControlTargetKind.values.firstWhere(
        (value) => value.name == json['targetKind'],
      ),
      title: json['title'] as String,
      serviceKey: json['serviceKey'] as String,
      bucketName: json['bucketName'] as String?,
      decidedAt: DateTime.parse(json['decidedAt'] as String),
    );
  }

  final String targetKey;
  final LocalControlActionKind actionKind;
  final LocalControlTargetKind targetKind;
  final String title;
  final String serviceKey;
  final String? bucketName;
  final DateTime decidedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'targetKey': targetKey,
      'actionKind': actionKind.name,
      'targetKind': targetKind.name,
      'title': title,
      'serviceKey': serviceKey,
      'bucketName': bucketName,
      'decidedAt': decidedAt.toIso8601String(),
    };
  }
}

class UserIgnoredLocalItem {
  const UserIgnoredLocalItem({
    required this.targetKey,
    required this.title,
    required this.subtitle,
  });

  final String targetKey;
  final String title;
  final String subtitle;
}

class UserHiddenLocalItem {
  const UserHiddenLocalItem({
    required this.targetKey,
    required this.title,
    required this.subtitle,
  });

  final String targetKey;
  final String title;
  final String subtitle;
}
