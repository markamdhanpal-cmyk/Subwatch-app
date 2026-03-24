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
  final showRenewalsZone =
      dueSoon.hasItems || upcomingRenewals.hasItems || renewalReminderItems.isNotEmpty;
  final homeChildren = <Widget>[
    _TotalsSummaryCard(
      presentation: totalsSummary,
      sourceStatus: sourceStatus,
      provenance: data.provenance,
      now: data.provenance.recordedAt,
      onPrimaryAction:
          sourceStatus.isActionEnabled ? () => shell._handleSyncEntry(sourceStatus) : null,
    ),
    if (homeAction != null) ...<Widget>[
      const SizedBox(height: 12),
      _HomeActionStrip(
        copy: homeAction,
        onReview: shell._openReviewDestination,
        onSync: () => shell._handleSyncEntry(sourceStatus),
        onOpenRenewals: shell._scrollHomeToRenewals,
      ),
    ],
    if (showRenewalsZone) ...<Widget>[
      const SizedBox(height: 16),
      _HomeRenewalsZoneCard(
        dueSoon: dueSoon,
        upcomingRenewals: upcomingRenewals,
        reminderItems: renewalReminderItems,
      ),
    ],
  ];

  return ListView(
    controller: shell._homeScrollController,
    key: const PageStorageKey<String>('destination-home-surface'),
    cacheExtent: 2000,
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
    children: homeChildren,
  );
}
