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
        explanationDescription:
            'This may be recurring, but SubWatch is waiting for stronger proof before it counts it as paid.',
        stampLabel: 'Still separate for now',
        cardRationale: _shortRationale(reviewItem.rationale),
        rationaleLabel: 'What SubWatch saw',
        rationale: reviewItem.rationale,
        whyFlaggedTitle: 'What stood out',
        whyFlagged: _whyFlagged(reviewItem.rationale),
        whyNotConfirmedTitle: 'Why it stays separate',
        whyNotConfirmed: _whyNotConfirmed(reviewItem.rationale),
        actionHintTitle: 'Best next step',
        actionHint:
            'Confirm it as paid only if you know you pay for it directly. Keep it as a benefit if access comes from a bundle or free access. Otherwise choose Not a subscription.',
        confirmLabel: 'Confirm as paid',
        benefitLabel: 'Keep as benefit',
        editLabel: 'Add manually instead',
        dismissLabel: 'Not a subscription',
        cardSemanticsLabel:
            'Subscription needs review: ${reviewItem.rationale}',
        confirmSemantics: 'Confirm as a paid subscription',
        benefitSemantics: 'Keep separate as a bundled or free benefit',
        editSemantics: 'Edit subscription details',
        dismissSemantics: 'Dismiss as not a subscription',
      );
    }

    return ReviewQueueItemPresentation(
      explanationTitle: 'Needs a clearer service',
      explanationDescription:
          'This may be recurring, but the service details are still too unclear to confirm safely.',
      stampLabel: 'Service still unclear',
      cardRationale: _shortRationale(reviewItem.rationale),
      rationaleLabel: 'What SubWatch saw',
      rationale: reviewItem.rationale,
      whyFlaggedTitle: 'What stood out',
      whyFlagged:
          'The message looked recurring, but SubWatch could not identify the service clearly enough.',
      whyNotConfirmedTitle: 'Why it stays separate',
      whyNotConfirmed:
          'SubWatch does not auto-confirm when the service name or billing proof is still unclear.',
      actionHintTitle: 'Best next step',
      actionHint:
          'If you recognise it, add it manually on this device. Otherwise choose Not a subscription.',
      confirmLabel: null,
      benefitLabel: null,
      editLabel: 'Add manually',
      dismissLabel: 'Not a subscription',
      cardSemanticsLabel: 'Review item needs details: ${reviewItem.rationale}',
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
    return 'The message looked more recurring than a one-off payment, so SubWatch kept it visible for review.';
  }

  static String _whyNotConfirmed(String rationale) {
    final lower = rationale.toLowerCase();
    if (lower.contains('setup intent') || lower.contains('mandate')) {
      return 'Setup messages alone do not prove that a paid subscription is already active.';
    }
    if (lower.contains('micro verification')) {
      return 'A tiny verification charge is not strong enough proof of a paid subscription by itself.';
    }
    return 'A payment-like or recurring-looking message alone is not enough to confirm an active paid subscription.';
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
