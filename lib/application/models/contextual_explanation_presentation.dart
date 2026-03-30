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
          actionLabel: 'Why it\'s here',
          title: 'Why this is here',
          description: 'This looks strong enough to count as paid.',
          bullets: <String>[
            'Setup or one-time payments do not count.',
            'Weaker signals stay in Review or Benefits.',
            'A later scan can update this.',
          ],
        );
      case DashboardBucket.needsReview:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it\'s separate',
          title: 'Why this stays separate',
          description: 'This looked recurring, but not proven enough yet.',
          bullets: <String>[
            'It stays visible without counting as paid.',
            'Weak billing stays out of your paid list.',
            'A later scan or your choice can settle it.',
          ],
        );
      case DashboardBucket.trialsAndBenefits:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it\'s separate',
          title: 'Why this stays separate',
          description: 'This looks like bundled, free, or trial access.',
          bullets: <String>[
            'Bundled access does not count as paid.',
            'Benefits stay visible without inflating your paid list.',
            'Later billing can move it.',
          ],
        );
      case DashboardBucket.hidden:
        return const ContextualExplanationPresentation(
          actionLabel: 'Why it\'s hidden',
          title: 'Why this is hidden',
          description: 'You hid this from the main view.',
          bullets: <String>[
            'Hidden items do not count toward totals.',
            'You can restore them later.',
            'Hiding only changes this phone view.',
          ],
        );
    }
  }

  factory ContextualExplanationPresentation.forReviewItem(ReviewItem item) {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(item);
    final description = item.reasonLine.isNotEmpty ? item.reasonLine : item.rationale;
    final bullets = item.detailsBullets.isNotEmpty
        ? item.detailsBullets
        : <String>[
            'It stays separate until you decide.',
            'Bundles, mandates, and tiny charges stay cautious.',
            'Your choice stays on this phone and can be undone.',
          ];

    if (descriptor.canConfirm) {
      return ContextualExplanationPresentation(
        actionLabel: 'Why it needs review',
        title: 'Why this item is in review',
        description: description,
        bullets: bullets,
      );
    }

    return ContextualExplanationPresentation(
      actionLabel: 'Why it needs review',
      title: 'Why this item still needs review',
      description: description,
      bullets: item.detailsBullets.isNotEmpty
          ? item.detailsBullets
          : <String>[
              'SubWatch does not guess the service name.',
              'It stays separate while the evidence is unclear.',
              'Add it as a subscription, dismiss it, or wait.',
            ],
    );
  }

  factory ContextualExplanationPresentation.forRuntimeStatus(
    RuntimeLocalMessageSourceStatus status,
  ) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return const ContextualExplanationPresentation(
          actionLabel: 'How this works',
          title: 'Why you\'re seeing a preview',
          description: 'This is a preview before your first scan.',
          bullets: <String>[
            'It does not come from your messages.',
            'It stays until you choose a scan.',
            'Fresh and saved views stay labeled.',
          ],
        );
      case RuntimeLocalMessageSourceTone.fresh:
        return const ContextualExplanationPresentation(
          actionLabel: 'How this works',
          title: 'What you\'re seeing',
          description: 'These results came from your last scan.',
          bullets: <String>[
            'A scan runs only when you ask for it.',
            'This view replaces the older one.',
            'Saved and unavailable views stay labeled.',
          ],
        );
      case RuntimeLocalMessageSourceTone.restored:
        return const ContextualExplanationPresentation(
          actionLabel: 'How this works',
          title: 'Why you\'re seeing last results',
          description: 'These are your last saved results.',
          bullets: <String>[
            'Last results stay separate from new scans.',
            'The last scan time stays visible.',
            'Scan again when you want fresh results.',
          ],
        );
      case RuntimeLocalMessageSourceTone.caution:
        return const ContextualExplanationPresentation(
          actionLabel: 'How this works',
          title: 'Why this isn\'t updated',
          description: 'SMS access is off, so this can\'t update.',
          bullets: <String>[
            'SubWatch reads messages only when you allow it.',
            'It never claims a fresh scan without access.',
            'Turn access on when you want a new result.',
          ],
        );
      case RuntimeLocalMessageSourceTone.unavailable:
        return const ContextualExplanationPresentation(
          actionLabel: 'How this works',
          title: 'Why scanning isn\'t available',
          description: 'This phone can\'t scan messages here.',
          bullets: <String>[
            'SubWatch does not pretend a fresh scan happened.',
            'This does not mean background reading is on.',
            'Last results stay labeled.',
          ],
        );
    }
  }

  final String actionLabel;
  final String title;
  final String description;
  final List<String> bullets;
}
