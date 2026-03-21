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
              'This service is counted as paid because the current message evidence is strong enough.',
          bullets: <String>[
            'Confirmed subscriptions need stronger proof than a setup, mandate, or one-time payment alone.',
            'SubWatch keeps weaker signals in Review or separate access instead of inflating this list.',
            'A later refresh can replace this snapshot cleanly if the device SMS picture changes.',
          ],
        );
      case DashboardBucket.needsReview:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it is separate',
          title: 'Why this stays separate',
          description:
              'This looked recurring, but SubWatch does not have enough proof to count it as paid.',
          bullets: <String>[
            'Review keeps uncertain recurring signals visible without promoting them into confirmed subscriptions.',
            'Payment-like, setup, or weak recurring messages stay out of active paid counts on purpose.',
            'A later refresh or your review decision can clarify what belongs here.',
          ],
        );
      case DashboardBucket.trialsAndBenefits:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it is separate',
          title: 'Why this stays separate',
          description:
              'This looks like bundled, free, or trial access rather than a direct paid subscription.',
          bullets: <String>[
            'Bundled or free access is not counted as an active paid subscription.',
            'This section keeps telecom offers and trial-like access visible without inflating confirmed subscriptions.',
            'A later refresh can replace this snapshot if stronger paid evidence appears.',
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
            'This looked recurring, but SubWatch is still waiting for proof strong enough to count it as paid.',
        bullets: <String>[
          'It stays separate until you decide or stronger evidence appears in a later refresh.',
          'Bundles, mandates, micro-charges, and weak recurring signals are treated carefully on purpose.',
          'Any decision you make stays local to this device and can be undone later.',
        ],
      );
    }

    return const ContextualExplanationPresentation(
      actionLabel: 'Why it needs review',
      title: 'Why this item still needs review',
      description:
          'This looked recurring, but the service details are still too unclear to confirm safely.',
      bullets: <String>[
        'SubWatch does not guess the service when identity is still weak.',
        'This item stays separate while the evidence remains unclear.',
        'You can add it manually on this device, dismiss it, or wait for a later refresh.',
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
              'This sample view lets you understand the layout before your first message scan.',
          bullets: <String>[
            'The sample view does not come from your messages.',
            'It stays visible until you choose a message scan.',
            'Fresh and saved views stay labeled separately so the current state stays honest.',
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
              'SMS access is currently off, so this view is limited to a saved view or another local view already on this device.',
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
            'Keeping this local view visible does not mean SubWatch is reading SMS in the background.',
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

