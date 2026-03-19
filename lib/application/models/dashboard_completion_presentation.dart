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
    final observedCount = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.needsReview)
        .length;
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
        eyebrow: 'Sample preview',
        title: 'See what SubWatch can surface before your first scan',
        description:
            'This demo uses realistic local billing examples so you can understand the result before granting SMS access.',
        bullets: <String>[
          'Confirmed subscriptions, review-needed items, and bundled benefits stay clearly separated.',
          'Your first scan replaces this sample with results from this device only.',
          'SMS is read only when you ask for it, and messages stay local.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: true,
        learnMoreActionLabel: 'How it works',
      );
    }

    if (accessState == LocalMessageSourceAccessState.deviceLocalDenied) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.standard,
        showPanel: true,
        eyebrow: 'Next step',
        title: 'Turn on SMS access to refresh',
        description:
            'Without SMS access, SubWatch can only show safe local results.',
        bullets: <String>[
          'SMS is read only when you refresh from this device.',
          'Confirmed subscriptions appear only when the signal is strong enough.',
          'Uncertain items stay separate and review actions stay local.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: true,
        learnMoreActionLabel: 'About',
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
        learnMoreActionLabel: 'About',
      );
    }

    if (hasDeviceSmsSnapshot && confirmedCount == 0 && !hasAnyUsefulState) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan finished successfully',
        title: 'No subscriptions confirmed yet',
        description:
            'SubWatch checked your SMS, but it did not see enough proof to count anything as a subscription yet.',
        bullets: <String>[
          'SubWatch confirms subscriptions only when renewal or plan evidence is strong enough.',
          'Anything unclear stays separate instead of being counted too early.',
          'You can refresh again later while keeping this view honest.',
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
        eyebrow: 'Scan finished successfully',
        title: 'Nothing confirmed yet',
        description:
            'SubWatch found possible recurring items and kept them separate on purpose.',
        bullets: <String>[
          'A confirmed subscription needs stronger proof than these messages provide right now.',
          'Review is where you decide what to confirm or dismiss.',
          'Undo stays available if you need to recover an item later.',
        ],
        primaryAction: DashboardCompletionPrimaryAction.review,
        primaryActionLabel: 'Go to Review',
        showLearnMoreAction: true,
        learnMoreActionLabel: 'How it works',
      );
    }

    if (hasDeviceSmsSnapshot && confirmedCount == 0 && observedCount > 0) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan finished successfully',
        title: 'Nothing confirmed yet',
        description:
            'SubWatch saw recurring-looking signals, but not strongly enough to confirm them as paid subscriptions.',
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
        eyebrow: 'Scan finished successfully',
        title: 'Nothing confirmed yet',
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
