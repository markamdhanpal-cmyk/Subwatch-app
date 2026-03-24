import '../../domain/entities/review_item.dart';
import 'review_item_action_models.dart';

class ReviewQueueItemPresentation {
  const ReviewQueueItemPresentation({
    required this.explanationTitle,
    required this.explanationDescription,
    required this.stampLabel,
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
        explanationTitle: 'Needs your review',
        explanationDescription: 'Looks recurring, but still needs review.',
        stampLabel: 'You decide',
        cardRationale: _shortRationale(reviewItem.rationale),
        rationaleLabel: 'What we saw',
        rationale: reviewItem.rationale,
        whyFlaggedTitle: 'Why it showed up',
        whyFlagged: _whyFlagged(reviewItem.rationale),
        whyNotConfirmedTitle: 'Why it stays separate',
        whyNotConfirmed: _whyNotConfirmed(reviewItem.rationale),
        actionHintTitle: 'How to decide',
        actionHint:
            'Confirm if you pay. Bundle if included. Otherwise choose Not mine.',
        confirmLabel: 'Confirm',
        benefitLabel: 'Bundle',
        editLabel: 'Add manually',
        dismissLabel: 'Not mine',
        cardSemanticsLabel:
            'Subscription needs review: ${reviewItem.rationale}',
        confirmSemantics: 'Confirm as a paid subscription',
        benefitSemantics: 'Keep as bundled or included access',
        editSemantics: 'Edit subscription details',
        dismissSemantics: 'Mark as not yours',
      );
    }

    return ReviewQueueItemPresentation(
      explanationTitle: 'Needs a clearer service',
      explanationDescription: 'Looks recurring, but the service isn\'t clear yet.',
      stampLabel: 'Service unclear',
      cardRationale: _shortRationale(reviewItem.rationale),
      rationaleLabel: 'What we saw',
      rationale: reviewItem.rationale,
      whyFlaggedTitle: 'Why it showed up',
      whyFlagged:
          'The message looked recurring, but the service name stayed unclear.',
      whyNotConfirmedTitle: 'Why it stays separate',
      whyNotConfirmed: 'SubWatch does not confirm unclear services or billing.',
      actionHintTitle: 'How to decide',
      actionHint: 'If you recognise it, add it. Otherwise choose Not mine.',
      confirmLabel: null,
      benefitLabel: null,
      editLabel: 'Add manually',
      dismissLabel: 'Not mine',
      cardSemanticsLabel: 'Review item needs details: ${reviewItem.rationale}',
      confirmSemantics: null,
      benefitSemantics: null,
      editSemantics: 'Edit subscription details',
      dismissSemantics: 'Mark as not yours',
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
      return 'It looked like recurring billing setup.';
    }
    if (lower.contains('micro verification')) {
      return 'It looked like a small verification charge.';
    }
    return 'It looked more recurring than a one-off payment.';
  }

  static String _whyNotConfirmed(String rationale) {
    final lower = rationale.toLowerCase();
    if (lower.contains('setup intent') || lower.contains('mandate')) {
      return 'Setup messages alone do not prove a paid subscription.';
    }
    if (lower.contains('micro verification')) {
      return 'A tiny verification charge is not enough alone.';
    }
    return 'One recurring-looking message is not enough to confirm it.';
  }

  final String explanationTitle;
  final String explanationDescription;
  final String stampLabel;
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
