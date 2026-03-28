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
  );
  final visibleSubscriptionCount = data.cards
          .where(
            (card) =>
                card.bucket == DashboardBucket.confirmedSubscriptions ||
                card.bucket == DashboardBucket.trialsAndBenefits,
          )
          .length +
      data.manualSubscriptions.length;
  final showCompletedState = homeAction == null &&
      sourceStatus.tone == RuntimeLocalMessageSourceTone.fresh &&
      visibleSubscriptionCount > 0;
  final homeChildren = <Widget>[
    _TotalsSummaryCard(
      presentation: totalsSummary,
      sourceStatus: sourceStatus,
    ),
    const SizedBox(height: DashboardSpacing.large),
    _HomeRenewalsZoneCard(
      dueSoon: dueSoon,
      upcomingRenewals: upcomingRenewals,
      reminderItems: renewalReminderItems,
    ),
    const SizedBox(height: DashboardSpacing.large),
    if (homeAction != null) ...<Widget>[
      _HomeActionStrip(
        copy: homeAction,
        subscriptionCount: visibleSubscriptionCount,
        reviewCount: data.reviewQueue.length,
        dueSoonCount: dueSoon.items.length,
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
      const SizedBox(height: DashboardSpacing.large),
    ],
    if (showCompletedState) ...<Widget>[
      _HomeCompletedState(
        onOpenSubscriptions: () async {
          shell._selectDestination(_DashboardDestination.subscriptions);
        },
      ),
      const SizedBox(height: DashboardSpacing.large),
    ],
    _HomeTrustRow(
      sourceStatus: sourceStatus,
      totalsSummary: totalsSummary,
      data: data,
      onOpenTrustSheet: shell._showHowSubWatchWorksSheet,
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
