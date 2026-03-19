import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';
import '../../domain/enums/dashboard_bucket.dart';
import '../models/review_item_action_models.dart';
import '../models/runtime_local_message_source_status.dart';

class ContextualExplanationPresentation {
  const ContextualExplanationPresentation({
    required this.actionLabel,
    required this.title,
    required this.description,
    required this.bullets,
  });

  factory ContextualExplanationPresentation.forDashboardCard(
    DashboardCard card,
  ) {
    switch (card.bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it is listed',
          title: 'Why this is listed',
          description:
              'This service is counted as active because the current signal is strong enough to treat it as a paid subscription.',
          bullets: <String>[
            'Confirmed subscriptions require stronger evidence than a payment, setup, or micro-charge alone.',
            'This card appears in confirmed subscriptions because it passed the conservative threshold.',
            'A later refresh can replace the snapshot cleanly if the device SMS view changes.',
          ],
        );
      case DashboardBucket.needsReview:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it is separate',
          title: 'Why this is separate',
          description:
              'This signal looked recurring, but it is not strong enough to count as an active paid subscription.',
          bullets: <String>[
            'Observed signals stay visible without being promoted into confirmed subscriptions.',
            'Payment-like, setup, or weak recurring messages are kept out of active paid counts.',
            'Review stays the only place for an explicit decision.',
          ],
        );
      case DashboardBucket.trialsAndBenefits:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it is separate',
          title: 'Why this is separate',
          description:
              'This service is shown separately because the current signal looks like a bundled benefit, free access, or a trial.',
          bullets: <String>[
            'Bundled or free access is not counted as an active paid subscription.',
            'This section keeps telecom offers and trial-like access visible without inflating confirmed subscriptions.',
            'A later refresh can replace the snapshot if stronger paid evidence appears.',
          ],
        );
      case DashboardBucket.hidden:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it is hidden',
          title: 'Why this item is hidden',
          description:
              'This item is hidden from the active dashboard because it is not part of the current visible subscription view.',
          bullets: <String>[
            'Hidden items do not count as active subscriptions.',
            'They can be restored later if you change your mind.',
            'This stays a local overlay decision and does not rewrite the underlying trust model.',
          ],
        );
    }
  }

  factory ContextualExplanationPresentation.forReviewItem(ReviewItem item) {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(item);

    if (descriptor.canConfirm) {
      return const ContextualExplanationPresentation(
        actionLabel: 'Why it needs review',
        title: 'Why this item is in review',
        description:
            'This signal looks recurring, but it is not safe to confirm automatically yet.',
        bullets: <String>[
          'SubWatch keeps limited-confidence recurring signals separate from confirmed subscriptions.',
          'This item is not counted as active paid until you make an explicit decision.',
          'You can confirm it, hide it from review, or undo a later decision.',
        ],
      );
    }

    return const ContextualExplanationPresentation(
      actionLabel: 'Why it needs review',
      title: 'Why this item still needs review',
      description:
          'This signal looks recurring, but the service is not identified clearly enough to confirm automatically.',
      bullets: <String>[
        'Service identity is still too unclear to move this into confirmed subscriptions safely.',
        'This item is not counted as active paid while the signal remains uncertain.',
        'You can keep it separate, hide it from review, or wait for a later refresh.',
      ],
    );
  }

  factory ContextualExplanationPresentation.forRuntimeStatus(
    RuntimeLocalMessageSourceStatus status,
  ) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return const ContextualExplanationPresentation(
          actionLabel: 'About this view',
          title: 'Why the sample view is showing',
          description:
              'The sample view lets you understand the layout before your first message scan.',
          bullets: <String>[
            'The sample view does not come from your messages.',
            'It stays visible until you choose a message scan.',
            'Fresh and restored local snapshots are labeled separately so the current state stays honest.',
          ],
        );
      case RuntimeLocalMessageSourceTone.fresh:
        return const ContextualExplanationPresentation(
          actionLabel: 'About this view',
          title: 'What this refresh means',
          description:
              'This view came from a direct device SMS refresh on this device.',
          bullets: <String>[
            'A fresh refresh recomputes the derived snapshot from device SMS when you ask for it.',
            'The current snapshot replaces older derived state instead of appending duplicate results.',
            'Restored snapshots and unavailable states stay labeled separately from a fresh read.',
          ],
        );
      case RuntimeLocalMessageSourceTone.restored:
        return const ContextualExplanationPresentation(
          actionLabel: 'About this view',
          title: 'What a saved view means',
          description:
              'This view was opened from a saved local snapshot and is not the same as a new message check.',
          bullets: <String>[
            'Saved views stay clearly separate from fresh message checks.',
            'The last known check timing stays visible so you can judge freshness.',
            'Check your messages again when you want a fresh device-backed view.',
          ],
        );
      case RuntimeLocalMessageSourceTone.caution:
        return const ContextualExplanationPresentation(
          actionLabel: 'About this view',
          title: 'Why this is not a fresh refresh',
          description:
              'SMS access is currently off, so this view stays limited to safe local state.',
          bullets: <String>[
            'SubWatch does not read device SMS unless access is allowed and you ask for a refresh.',
            'Denied access never pretends a fresh device snapshot happened.',
            'The current view stays separate from a fresh device-backed snapshot.',
          ],
        );
      case RuntimeLocalMessageSourceTone.unavailable:
        return const ContextualExplanationPresentation(
          actionLabel: 'About this view',
          title: 'Why device SMS refresh is unavailable',
          description:
              'This device cannot provide a direct local SMS refresh for the current snapshot.',
          bullets: <String>[
            'Unavailable access does not pretend a fresh device snapshot happened.',
            'Safe local state can remain visible without turning into background monitoring.',
            'Restored snapshots still stay labeled separately from fresh device-backed views.',
          ],
        );
    }
  }

  final String actionLabel;
  final String title;
  final String description;
  final List<String> bullets;
}

