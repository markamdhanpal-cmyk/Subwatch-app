part of '../dashboard_shell.dart';

class _DashboardHomeScreen extends ConsumerWidget {
  const _DashboardHomeScreen({
    required this.shell,
  });

  final _DashboardShellState shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenData = ref.watch(dashboardHomeScreenDataProvider);
    return _buildDashboardHomeScreen(
      shell: shell,
      data: screenData.data,
      sourceStatus: screenData.sourceStatus,
      totalsSummary: screenData.totalsSummary,
      dueSoon: screenData.dueSoon,
      upcomingRenewals: screenData.upcomingRenewals,
      renewalReminderItems: screenData.renewalReminderItems,
    );
  }
}

Widget _buildDashboardHomeScreen({
  required _DashboardShellState shell,
  required RuntimeDashboardSnapshot data,
  required RuntimeLocalMessageSourceStatus sourceStatus,
  required DashboardTotalsSummaryPresentation totalsSummary,
  required DashboardDueSoonPresentation dueSoon,
  required DashboardUpcomingRenewalsPresentation upcomingRenewals,
  required List<DashboardRenewalReminderItemPresentation> renewalReminderItems,
}) {
  final homeAction = _HomeActionCopy.fromState(
    sourceStatus: sourceStatus,
    reviewCount: data.reviewQueue.length,
    dueSoonCount: dueSoon.items.length,
    hasSpendHeroAction:
        totalsSummary.activePaidCount == 0 && !totalsSummary.hasEstimatedSpend,
  );
  final visibleSubscriptionCount = data.cards
          .where(
            (card) =>
                card.bucket == DashboardBucket.confirmedSubscriptions ||
                card.bucket == DashboardBucket.trialsAndBenefits,
          )
          .length +
      data.manualSubscriptions.length;
  final homeChildren = <Widget>[
    _TotalsSummaryCard(
      presentation: totalsSummary,
      sourceStatus: sourceStatus,
      provenance: data.provenance,
      now: data.provenance.recordedAt,
      onPrimaryAction:
          sourceStatus.isActionEnabled ? () => shell._handleSyncEntry(sourceStatus) : null,
    ),
    const SizedBox(height: DashboardSpacing.large),
    _HomeRenewalsZoneCard(
      dueSoon: dueSoon,
      upcomingRenewals: upcomingRenewals,
      reminderItems: renewalReminderItems,
    ),
    const SizedBox(height: DashboardSpacing.large),
    _HomeInsightCard(
      sourceStatus: sourceStatus,
      totalsSummary: totalsSummary,
      data: data,
      onOpenTrustSheet: shell._showHowSubWatchWorksSheet,
    ),
    const SizedBox(height: DashboardSpacing.large),
    _HomeActionStrip(
      copy: homeAction,
      subscriptionCount: visibleSubscriptionCount,
      reviewCount: data.reviewQueue.length,
      sourceStatus: sourceStatus,
      onReview: shell._openReviewDestination,
      onSync: () => shell._handleSyncEntry(sourceStatus),
      onOpenRenewals: shell._scrollHomeToRenewals,
      onOpenSubscriptions: () async {
        shell._selectDestination(_DashboardDestination.subscriptions);
      },
      onOpenSettings: () async {
        shell._openSettingsDestination();
      },
    ),
  ];

  return ListView(
    controller: shell._homeScrollController,
    key: const PageStorageKey<String>('destination-home-surface'),
    cacheExtent: 2000,
    padding: DashboardSpacing.screenInset,
    children: homeChildren,
  );
}
