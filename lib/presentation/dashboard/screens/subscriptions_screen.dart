part of '../dashboard_shell.dart';

class _DashboardSubscriptionsScreen extends ConsumerWidget {
  const _DashboardSubscriptionsScreen({
    required this.shell,
  });

  final _DashboardShellState shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenData = ref.watch(dashboardSubscriptionsScreenDataProvider);
    ref.watch(
      dashboardLocalControlsProvider.select(
        (state) => (
          localControlTargetsInFlight: state.localControlTargetsInFlight,
          localRenewalReminderTargetsInFlight:
              state.localRenewalReminderTargetsInFlight,
          manualSubscriptionTargetsInFlight:
              state.manualSubscriptionTargetsInFlight,
          localServicePresentationTargetsInFlight:
              state.localServicePresentationTargetsInFlight,
        ),
      ),
    );
    return _buildDashboardSubscriptionsScreen(
      shell: shell,
      data: screenData.data,
      serviceView: screenData.serviceView,
      visibleServiceSections: screenData.visibleServiceSections,
      upcomingRenewals: screenData.upcomingRenewals,
      renewalReminderItems: screenData.renewalReminderItems,
    );
  }
}

Widget _buildDashboardSubscriptionsScreen({
  required _DashboardShellState shell,
  required RuntimeDashboardSnapshot data,
  required DashboardServiceViewResult serviceView,
  required List<DashboardServiceSectionView> visibleServiceSections,
  required DashboardUpcomingRenewalsPresentation upcomingRenewals,
  required List<DashboardRenewalReminderItemPresentation> renewalReminderItems,
}) {
  final visibleManualSubscriptions = shell._visibleManualSubscriptions(
    data.manualSubscriptions,
    serviceView.controls,
  );
  final showManualSection =
      shell._shouldShowManualSubscriptions(serviceView.controls.filterMode) &&
          visibleManualSubscriptions.isNotEmpty;
  final orderedServiceSections = visibleServiceSections.toList(growable: false)
    ..sort((left, right) {
      final leftPriority = shell._subscriptionsSectionPriority(
        left.bucket,
        serviceView.controls.filterMode,
        visibleServiceSections: visibleServiceSections,
      );
      final rightPriority = shell._subscriptionsSectionPriority(
        right.bucket,
        serviceView.controls.filterMode,
        visibleServiceSections: visibleServiceSections,
      );
      return leftPriority.compareTo(rightPriority);
    });
  final showSingleEmptySection =
      orderedServiceSections.isEmpty && !showManualSection;
  final emptyBucket = shell._emptyStateBucketForFilter(
    serviceView.controls.filterMode,
  );
  final visibleCount =
      serviceView.totalVisibleCount + visibleManualSubscriptions.length;

  return ListView(
    key: const ValueKey<String>('destination-subscriptions-surface'),
    padding: DashboardSpacing.secondaryScreenInsetWithBottomNav,

    children: <Widget>[
      _SubscriptionsBrowseHeader(
        visibleCount: visibleCount,
        controls: serviceView.controls,
        hasManualEntries: visibleManualSubscriptions.isNotEmpty,
      ),
      const SizedBox(height: DashboardSpacing.screenBlockGap),
      _ServiceViewControlsPanel(
        searchController: shell._serviceSearchController,
        controls: serviceView.controls,
        availableFilterModes: _DashboardShellState._subscriptionsFilterModes,
        onSortChanged: shell._setServiceSortMode,
        onFilterChanged: shell._setServiceFilterMode,
        onClear: shell._clearServiceViewControls,
      ),
      const SizedBox(height: DashboardSpacing.screenBlockGap),
      if (serviceView.controls.restrictsResults &&
          !serviceView.hasMatches &&
          visibleManualSubscriptions.isEmpty) ...<Widget>[
        _ServiceViewEmptyState(
          onClear: shell._clearServiceViewControls,
        ),
      ] else ...<Widget>[
        ...orderedServiceSections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(
              bottom: DashboardSpacing.compactSectionGap,
            ),
            child: shell._buildSubscriptionsSection(
              section: section,
              data: data,
              upcomingRenewals: upcomingRenewals,
              renewalReminderItems: renewalReminderItems,
              controls: serviceView.controls,
            ),
          ),
        ),
        if (showSingleEmptySection)
          _DashboardSection(
            key: ValueKey<String>('section-${emptyBucket.name}'),
            title: shell._serviceSectionTitle(emptyBucket),
            caption: 'Nothing visible in this view yet.',
            children: <Widget>[
              _EmptySectionText(
                title: shell._serviceSectionEmptyTitle(emptyBucket),
                message: shell._serviceSectionEmptyMessage(emptyBucket),
                icon: shell._emptyStateIcon(emptyBucket),
              ),
            ],
          ),
        if (showManualSection)
          Padding(
            padding: const EdgeInsets.only(
              top: 2,
              bottom: DashboardSpacing.compactSectionGap,
            ),
            child: _DashboardSection(
              key: const ValueKey<String>('section-manualSubscriptions'),
              title: 'Added by you',
              caption: visibleManualSubscriptions.length == 1
                  ? '1 subscription you added on this phone.'
                  : '${visibleManualSubscriptions.length} subscriptions you added on this phone.',
              children: shell._buildManualSubscriptionRows(
                visibleManualSubscriptions,
                upcomingRenewals,
                renewalReminderItems,
              ),
            ),
          ),
      ],
    ],
  );
}
