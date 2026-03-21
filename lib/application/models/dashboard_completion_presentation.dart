import '../../domain/enums/dashboard_bucket.dart';
import '../use_cases/load_runtime_dashboard_use_case.dart';
import 'local_message_source_access_state.dart';
import 'runtime_snapshot_provenance.dart';

enum DashboardCompletionPrimaryAction {
  none,
  sync,
  review,
  learn,
}

enum DashboardCompletionKind {
  standard,
  zeroConfirmedRescue,
}

class DashboardCompletionPresentation {
  const DashboardCompletionPresentation({
    required this.kind,
    required this.showPanel,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.bullets,
    required this.primaryAction,
    required this.primaryActionLabel,
    required this.showLearnMoreAction,
    required this.learnMoreActionLabel,
  });

  factory DashboardCompletionPresentation.fromSnapshot(
    RuntimeDashboardSnapshot snapshot,
  ) {
    final accessState = snapshot.messageSourceSelection.accessState;
    final hasDeviceSmsSnapshot =
        snapshot.provenance.sourceKind == RuntimeSnapshotSourceKind.deviceSms;
    final confirmedCount = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.confirmedSubscriptions)
        .length;
    final observedCount = snapshot.reviewQueue.length;
    final trialCount = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
        .length;
    final recoveryCount = snapshot.confirmedReviewItems.length +
        snapshot.dismissedReviewItems.length;
    final hasDecisions = snapshot.reviewQueue.isNotEmpty;
    final hasAnyUsefulState = confirmedCount > 0 ||
        observedCount > 0 ||
        trialCount > 0 ||
        hasDecisions ||
        recoveryCount > 0;

    if (accessState == LocalMessageSourceAccessState.sampleDemo) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.standard,
        showPanel: true,
        eyebrow: 'Before your first scan',
        title: 'See how SubWatch stays careful before your first scan',
        description:
            'This preview shows realistic recurring examples so you can understand SubWatch before granting SMS access.',
        bullets: <String>[
          'Confirmed subscriptions, items that need review, and separate access stay clearly separated.',
          'Your first scan replaces this preview with results from this device only.',
          'SMS is read only when you ask for it, and messages stay local.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: true,
        learnMoreActionLabel: 'How SubWatch works',
      );
    }

    if (accessState == LocalMessageSourceAccessState.deviceLocalDenied) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.standard,
        showPanel: true,
        eyebrow: 'Next step',
        title: 'Turn on SMS access to refresh',
        description:
            'Without SMS access, SubWatch can only show a saved or limited local view.',
        bullets: <String>[
          'SMS is read only when you refresh from this device.',
          'Confirmed subscriptions appear only when the signal is strong enough.',
          'Uncertain items stay separate and review actions stay local.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: true,
        learnMoreActionLabel: 'How SubWatch works',
      );
    }

    if (accessState == LocalMessageSourceAccessState.deviceLocalUnavailable) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.standard,
        showPanel: true,
        eyebrow: 'This device is limited',
        title: 'SMS refresh is unavailable here',
        description: 'SubWatch cannot read SMS directly on this device.',
        bullets: <String>[
          'No background monitoring happens here.',
          'Restored local snapshots stay visibly distinct from fresh reads.',
          'Uncertain signals are never promoted into confirmed subscriptions automatically.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: true,
        learnMoreActionLabel: 'How SubWatch works',
      );
    }

    if (hasDeviceSmsSnapshot && confirmedCount == 0 && !hasAnyUsefulState) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan complete',
        title: 'No paid subscriptions confirmed yet',
        description:
            'SubWatch checked your SMS, but nothing looked paid and recurring strongly enough to count yet.',
        bullets: <String>[
          'SubWatch confirms subscriptions only when renewal or billing evidence is strong enough.',
          'Anything unclear stays separate instead of being counted too early.',
          'A later billing message can make the picture clearer.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.learn,
        primaryActionLabel: 'How SubWatch decides',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    if (hasDeviceSmsSnapshot && hasDecisions && confirmedCount == 0) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan complete',
        title: 'Review what SubWatch found',
        description:
            'Possible recurring items are waiting in Review instead of being counted too early.',
        bullets: <String>[
          'A confirmed subscription needs stronger proof than these messages provide right now.',
          'Review lets you confirm, keep separate, or dismiss each item.',
          'Undo stays available if you need to recover an item later.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.review,
        primaryActionLabel: 'Open Review',
        showLearnMoreAction: true,
        learnMoreActionLabel: 'How SubWatch works',
      );
    }

    if (hasDeviceSmsSnapshot && confirmedCount == 0 && observedCount > 0) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan complete',
        title: 'No paid subscriptions confirmed yet',
        description:
            'SubWatch noticed recurring-looking signals, but kept them separate until the proof is stronger.',
        bullets: <String>[
          'SubWatch only confirms a subscription when the recurring proof is stronger than these signals.',
          'Review stays separate so the dashboard does not overclaim.',
          'A later refresh can replace this snapshot cleanly when stronger evidence appears.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.learn,
        primaryActionLabel: 'How SubWatch decides',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    if (hasDeviceSmsSnapshot && confirmedCount == 0 && trialCount > 0) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan complete',
        title: 'No paid subscriptions confirmed yet',
        description:
            'SubWatch found access or benefit signals, but nothing strong enough to confirm as a paid subscription yet.',
        bullets: <String>[
          'Bundled or trial access stays separate from paid subscriptions on purpose.',
          'If stronger billing evidence appears later, a new scan replaces this snapshot cleanly.',
          'You can still review what was found, add something manually, or check how SubWatch decides.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.learn,
        primaryActionLabel: 'How SubWatch decides',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    return const DashboardCompletionPresentation(
      kind: DashboardCompletionKind.standard,
      showPanel: false,
      eyebrow: '',
      title: '',
      description: '',
      bullets: <String>[],
      primaryAction: DashboardCompletionPrimaryAction.none,
      primaryActionLabel: '',
      showLearnMoreAction: false,
      learnMoreActionLabel: '',
    );
  }

  final DashboardCompletionKind kind;
  final bool showPanel;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> bullets;
  final DashboardCompletionPrimaryAction primaryAction;
  final String primaryActionLabel;
  final bool showLearnMoreAction;
  final String learnMoreActionLabel;
}
