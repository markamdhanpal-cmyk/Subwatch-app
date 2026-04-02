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
        eyebrow: 'Preview',
        title: 'Preview your subscription view',
        description: 'See how confirmed, possible, and included items appear.',
        bullets: <String>[],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    if (accessState == LocalMessageSourceAccessState.deviceLocalDenied) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.standard,
        showPanel: true,
        eyebrow: 'Next step',
        title: 'Turn on SMS access',
        description: 'Without it, you\'ll only see your last results.',
        bullets: <String>[],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    if (accessState == LocalMessageSourceAccessState.deviceLocalUnavailable) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.standard,
        showPanel: true,
        eyebrow: 'This device is limited',
        title: 'Can\'t scan here',
        description: 'This phone can\'t scan messages.',
        bullets: <String>[],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    if (hasDeviceSmsSnapshot && confirmedCount == 0 && !hasAnyUsefulState) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan complete',
        title: 'No subscriptions found yet',
        description: 'Nothing looked like a paid subscription yet.',
        bullets: <String>[],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    if (hasDeviceSmsSnapshot && hasDecisions && confirmedCount == 0) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan complete',
        title: 'Possible items were kept separate',
        description: 'Some items look recurring, but billing is not confirmed.',
        bullets: <String>[],
        primaryAction: DashboardCompletionPrimaryAction.review,
        primaryActionLabel: 'Open Possible',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    if (hasDeviceSmsSnapshot && confirmedCount == 0 && observedCount > 0) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan complete',
        title: 'No subscriptions found yet',
        description: 'Some items are possible, but billing is not confirmed yet.',
        bullets: <String>[],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
        showLearnMoreAction: false,
        learnMoreActionLabel: '',
      );
    }

    if (hasDeviceSmsSnapshot && confirmedCount == 0 && trialCount > 0) {
      return const DashboardCompletionPresentation(
        kind: DashboardCompletionKind.zeroConfirmedRescue,
        showPanel: true,
        eyebrow: 'Scan complete',
        title: 'No subscriptions found yet',
        description: 'This looks bundled or trial-based, not paid.',
        bullets: <String>[],
        primaryAction: DashboardCompletionPrimaryAction.none,
        primaryActionLabel: '',
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

