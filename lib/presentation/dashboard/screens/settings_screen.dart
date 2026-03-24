part of '../dashboard_shell.dart';

class _DashboardSettingsScreen extends ConsumerWidget {
  const _DashboardSettingsScreen({
    required this.shell,
  });

  final _DashboardShellState shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenData = ref.watch(dashboardSettingsScreenDataProvider);
    ref.watch(
      dashboardSyncStateProvider.select(
        (state) => state.isSyncing,
      ),
    );
    ref.watch(
      dashboardReviewActionsProvider.select(
        (state) => state.targetsInFlight,
      ),
    );
    ref.watch(
      dashboardLocalControlsProvider.select(
        (state) => (
          isClearingAllData: state.isClearingAllData,
          localControlTargetsInFlight: state.localControlTargetsInFlight,
        ),
      ),
    );
    return _buildDashboardSettingsScreen(
      shell: shell,
      data: screenData.data,
      sourceStatus: screenData.sourceStatus,
      reminderItems: screenData.reminderItems,
    );
  }
}

Widget _buildDashboardSettingsScreen({
  required _DashboardShellState shell,
  required RuntimeDashboardSnapshot data,
  required RuntimeLocalMessageSourceStatus sourceStatus,
  required List<DashboardRenewalReminderItemPresentation> reminderItems,
}) {
  final recoveryChildren = shell._buildSettingsRecoveryChildren(data);
  final recoveryCount = data.confirmedReviewItems.length +
      data.benefitReviewItems.length +
      data.dismissedReviewItems.length +
      data.ignoredLocalItems.length +
      data.hiddenLocalItems.length;
  final quickActionRows = <Widget>[
    _SettingsNavRow(
      tileKey: const ValueKey<String>('settings-source-action'),
      icon: shell._settingsSourceActionIcon(sourceStatus),
      title: shell._isSyncing
          ? 'Checking messages'
          : shell._settingsSourceActionTitle(sourceStatus),
      subtitle: shell._isSyncing
          ? 'A scan is already running.'
          : shell._settingsSourceActionSubtitle(sourceStatus),
      onTap: shell._isSyncing || !sourceStatus.isActionEnabled
          ? null
          : () {
              shell._handleSyncEntry(sourceStatus);
            },
      trailing: shell._isSyncing
          ? Text(
              'Working...',
              style: Theme.of(shell.context).textTheme.labelMedium?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
            )
          : null,
    ),
  ];
  if (data.reviewQueue.isNotEmpty) {
    quickActionRows.add(const _SettingsGroupDivider());
    quickActionRows.add(
      _SettingsNavRow(
        tileKey: const ValueKey<String>('settings-open-review-action'),
        icon: Icons.rule_folder_outlined,
        title: data.reviewQueue.length == 1
            ? 'Review 1 item'
            : 'Review ${data.reviewQueue.length} items',
        subtitle: 'Confirm, keep separate, or dismiss uncertain items.',
        onTap: () {
          shell._openReviewDestination();
        },
      ),
    );
  }
  quickActionRows.add(const _SettingsGroupDivider());
  quickActionRows.add(
    _SettingsNavRow(
      tileKey: const ValueKey<String>('settings-add-manual-action'),
      icon: Icons.add_circle_outline,
      title: 'Add manually',
      subtitle: 'Track one yourself when scans miss it.',
      onTap: () {
        shell._showCreateManualSubscriptionForm();
      },
    ),
  );
  final settingsPanels = <Widget>[
    _SettingsGroupPanel(
      key: const ValueKey<String>('settings-quick-actions-panel'),
      title: 'Actions',
      subtitle: 'Refresh, review, or add one yourself.',
      children: quickActionRows,
    ),
  ];
  if (recoveryChildren.isNotEmpty) {
    settingsPanels.add(const SizedBox(height: 12));
    settingsPanels.add(
      _SettingsGroupPanel(
        key: const ValueKey<String>('section-settings-recovery'),
        title: 'Recent changes (${shell._countLabel(recoveryCount)})',
        children: recoveryChildren,
      ),
    );
  }
  settingsPanels.add(const SizedBox(height: 12));
  settingsPanels.add(
    _SettingsGroupPanel(
      key: const ValueKey<String>('settings-support-panel'),
      title: 'Help & privacy',
      children: <Widget>[
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-open-help'),
          icon: Icons.help_outline,
          title: 'Help & privacy',
          subtitle: 'What stays local. No raw SMS saved.',
          onTap: shell._showHelpAndPrivacySheet,
        ),
        const _SettingsGroupDivider(),
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-open-about'),
          icon: Icons.info_outline,
          title: 'About SubWatch',
          subtitle: 'What SubWatch tracks.',
          onTap: shell._showAboutSheet,
        ),
        const _SettingsGroupDivider(),
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-report-problem'),
          icon: Icons.bug_report_outlined,
          title: 'Report a problem',
          subtitle: 'Send an email report.',
          onTap: () => shell._reportProblem(
            data: data,
            sourceStatus: sourceStatus,
            reminderItems: reminderItems,
          ),
        ),
      ],
    ),
  );
  settingsPanels.add(const SizedBox(height: 12));
  settingsPanels.add(
    _SettingsGroupPanel(
      key: const ValueKey<String>('settings-data-panel'),
      title: 'Device data',
      children: <Widget>[
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-clear-all-data'),
          icon: Icons.delete_outline,
          title: 'Clear all data',
          subtitle: 'Delete summaries and decisions from this phone.',
          onTap: shell._isClearingAllData ? null : shell._confirmClearAllData,
          trailing: shell._isClearingAllData
              ? Text(
                  'Clearing...',
                  style: Theme.of(shell.context).textTheme.labelMedium?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                )
              : null,
        ),
      ],
    ),
  );

  return ListView(
    key: const ValueKey<String>('destination-settings-surface'),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),

    children: settingsPanels,
  );
}
