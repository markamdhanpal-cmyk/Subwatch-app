import '../../domain/entities/review_item.dart';
import 'review_item_action_models.dart';

class ReviewQueueItemPresentation {
  const ReviewQueueItemPresentation({
    required this.reasonLine,
    required this.detailsBullets,
    required this.confirmLabel,
    required this.benefitLabel,
    required this.editLabel,
    required this.dismissLabel,
    this.confirmSemantics,
    this.benefitSemantics,
    this.editSemantics,
    this.dismissSemantics,
  });

  factory ReviewQueueItemPresentation.fromReviewItem(ReviewItem reviewItem) {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(reviewItem);
    final lowerRationale = reviewItem.rationale.toLowerCase();
    final reasonLine = reviewItem.reasonLine.isNotEmpty
        ? reviewItem.reasonLine
        : _reasonLine(lowerRationale);
    final detailsBullets = reviewItem.detailsBullets.isNotEmpty
        ? reviewItem.detailsBullets
        : _detailsBullets(lowerRationale);

    if (descriptor.canConfirm) {
      return ReviewQueueItemPresentation(
        reasonLine: reasonLine,
        detailsBullets: detailsBullets,
        confirmLabel: 'Confirm',
        benefitLabel: 'Bundle',
        editLabel: 'Add subscription',
        dismissLabel: 'Not mine',
        confirmSemantics: 'Confirm as a paid subscription',
        benefitSemantics: 'Keep as included access or a bundle',
        editSemantics: 'Add this service as a subscription',
        dismissSemantics: 'Mark as not yours',
      );
    }

    return const ReviewQueueItemPresentation(
      reasonLine: 'Looks recurring, but the service is still unclear',
      detailsBullets: <String>[
        'A recurring-looking signal was found.',
        'The service name is still unclear.',
        'That is why SubWatch keeps it as possible until evidence improves.',
      ],
      confirmLabel: null,
      benefitLabel: null,
      editLabel: 'Add subscription',
      dismissLabel: 'Not mine',
      editSemantics: 'Add this service as a subscription',
      dismissSemantics: 'Mark as not yours',
    );
  }

  static String _reasonLine(String lowerRationale) {
    if (lowerRationale.contains('setup intent') ||
        lowerRationale.contains('mandate')) {
      return 'Recurring setup spotted, but billing is unconfirmed';
    }
    if (lowerRationale.contains('micro verification')) {
      return 'Only a small verification charge was found';
    }
    return 'Looks recurring, but still uncertain';
  }

  static List<String> _detailsBullets(String lowerRationale) {
    if (lowerRationale.contains('setup intent') ||
        lowerRationale.contains('mandate')) {
      return const <String>[
        'A recurring setup or mandate signal was found.',
        'No billed renewal evidence has been confirmed yet.',
        'That is why it stays in Possible for now.',
      ];
    }
    if (lowerRationale.contains('micro verification')) {
      return const <String>[
        'A small verification charge was found.',
        'Verification charges alone are not treated as active paid subscriptions.',
        'That is why it stays in Possible for now.',
      ];
    }
    return const <String>[
      'A recurring-looking signal was found.',
      'The evidence is still too weak to confirm it automatically.',
      'That is why it stays in Possible for now.',
    ];
  }

  final String reasonLine;
  final List<String> detailsBullets;
  final String? confirmLabel;
  final String? benefitLabel;
  final String editLabel;
  final String dismissLabel;
  final String? confirmSemantics;
  final String? benefitSemantics;
  final String? editSemantics;
  final String? dismissSemantics;
}
