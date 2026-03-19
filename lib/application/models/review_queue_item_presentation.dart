import '../../domain/entities/review_item.dart';
import 'review_item_action_models.dart';

class ReviewQueueItemPresentation {
  const ReviewQueueItemPresentation({
    required this.explanationTitle,
    required this.explanationDescription,
    required this.cardRationale,
    required this.rationaleLabel,
    required this.rationale,
    required this.whyFlaggedTitle,
    required this.whyFlagged,
    required this.whyNotConfirmedTitle,
    required this.whyNotConfirmed,
    required this.actionHintTitle,
    required this.actionHint,
    required this.confirmLabel,
    required this.benefitLabel,
    required this.editLabel,
    required this.dismissLabel,
    required this.cardSemanticsLabel,
    this.confirmSemantics,
    this.benefitSemantics,
    this.editSemantics,
    this.dismissSemantics,
  });

  factory ReviewQueueItemPresentation.fromReviewItem(ReviewItem reviewItem) {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(reviewItem);

    if (descriptor.canConfirm) {
      return ReviewQueueItemPresentation(
        explanationTitle: 'Needs review',
        explanationDescription:
            'This looks recurring enough to keep visible, but not safe enough to auto-confirm.',
        cardRationale: _shortRationale(reviewItem.rationale),
        rationaleLabel: 'Short reason',
        rationale: reviewItem.rationale,
        whyFlaggedTitle: 'Why this was flagged',
        whyFlagged: _whyFlagged(reviewItem.rationale),
        whyNotConfirmedTitle: 'Why it was not confirmed',
        whyNotConfirmed: _whyNotConfirmed(reviewItem.rationale),
        actionHintTitle: 'What you can do',
        actionHint:
            'Confirm it if you know it is paid, mark it as a benefit if it is bundled or free, or dismiss it if it does not belong here.',
        confirmLabel: 'Confirm as paid',
        benefitLabel: 'Mark as benefit',
        editLabel: 'Edit details',
        dismissLabel: 'Not a subscription',
        cardSemanticsLabel:
            'Subscription needs review: ${reviewItem.rationale}',
        confirmSemantics: 'Confirm as a paid subscription',
        benefitSemantics: 'Mark as a bundled or free benefit',
        editSemantics: 'Edit subscription details',
        dismissSemantics: 'Dismiss as not a subscription',
      );
    }

    return ReviewQueueItemPresentation(
      explanationTitle: 'Service unclear',
      explanationDescription:
          'This looks recurring, but the service is still too unclear to confirm safely.',
      cardRationale: _shortRationale(reviewItem.rationale),
      rationaleLabel: 'Short reason',
      rationale: reviewItem.rationale,
      whyFlaggedTitle: 'Why this was flagged',
      whyFlagged:
          'The message looked recurring, but SubWatch could not identify the service clearly enough.',
      whyNotConfirmedTitle: 'Why it was not confirmed',
      whyNotConfirmed:
          'SubWatch does not auto-confirm when the service name or billing proof is still unclear.',
      actionHintTitle: 'What you can do',
      actionHint:
          'Dismiss it if it does not belong here, or edit the details and track it manually on this device.',
      confirmLabel: null,
      benefitLabel: null,
      editLabel: 'Edit details',
      dismissLabel: 'Not a subscription',
      cardSemanticsLabel: 'Service unclear: ${reviewItem.rationale}',
      confirmSemantics: null,
      benefitSemantics: null,
      editSemantics: 'Edit subscription details',
      dismissSemantics: 'Dismiss as not a subscription',
    );
  }

  static String _shortRationale(String rationale) {
    if (rationale.endsWith('.')) {
      return rationale.substring(0, rationale.length - 1);
    }
    return rationale;
  }

  static String _whyFlagged(String rationale) {
    final lower = rationale.toLowerCase();
    if (lower.contains('setup intent') || lower.contains('mandate')) {
      return 'SubWatch saw setup or mandate signals that can lead to recurring billing.';
    }
    if (lower.contains('micro verification')) {
      return 'SubWatch saw a small verification-style charge that often appears near subscription setup.';
    }
    return 'The message looked recurring enough to keep visible instead of dropping it.';
  }

  static String _whyNotConfirmed(String rationale) {
    final lower = rationale.toLowerCase();
    if (lower.contains('setup intent') || lower.contains('mandate')) {
      return 'Setup messages alone do not prove that a paid subscription is already active.';
    }
    if (lower.contains('micro verification')) {
      return 'A tiny verification charge is not strong enough proof of a paid subscription by itself.';
    }
    return 'The billing proof is still too limited to move this into confirmed subscriptions automatically.';
  }

  final String explanationTitle;
  final String explanationDescription;
  final String cardRationale;
  final String rationaleLabel;
  final String rationale;
  final String whyFlaggedTitle;
  final String whyFlagged;
  final String whyNotConfirmedTitle;
  final String whyNotConfirmed;
  final String actionHintTitle;
  final String actionHint;
  final String? confirmLabel;
  final String? benefitLabel;
  final String editLabel;
  final String dismissLabel;
  final String cardSemanticsLabel;
  final String? confirmSemantics;
  final String? benefitSemantics;
  final String? editSemantics;
  final String? dismissSemantics;
}
