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
  final settingsReminderItems = reminderItems
      .where((item) => item.canConfigureReminder)
      .toList(growable: false);
  final recoveryChildren = shell._buildSettingsRecoveryChildren(data);
  final activeReminderCount =
      settingsReminderItems.where((item) => item.selectedPreset != null).length;
  final quickActionRows = <Widget>[
    _SettingsNavRow(
      tileKey: const ValueKey<String>('settings-source-action'),
      icon: shell._settingsSourceActionIcon(sourceStatus),
      title: shell._isSyncing
          ? 'Checking messages'
          : shell._settingsSourceActionTitle(sourceStatus),
      subtitle: shell._isSyncing
          ? 'Scan running now.'
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
            ? 'Open 1 possible item'
            : 'Open ${data.reviewQueue.length} possible items',
        subtitle: 'Kept separate from confirmed until evidence improves.',
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
      title: 'Add subscription',
      subtitle: 'Track one yourself.',
      onTap: () {
        shell._showCreateManualSubscriptionForm();
      },
    ),
  );
  final settingsPanels = <Widget>[
    const _SettingsTrustCenterHeader(),
    const SizedBox(height: DashboardSpacing.screenBlockGap),
    const _SettingsSectionLead(
      title: 'Privacy & trust',
      caption:
          'How SubWatch behaves on this phone, and why the product stays careful by design.',
    ),
    const SizedBox(height: 10),
    const _SettingsTrustPanel(
      key: ValueKey<String>('settings-trust-panel'),
      title: 'Private on this phone',
      subtitle: 'Your messages are checked on-device',
    ),
    const SizedBox(height: DashboardSpacing.screenBlockGap),
    _SettingsGroupPanel(
      key: const ValueKey<String>('settings-quick-actions-panel'),
      title: 'Actions',
      subtitle:
          'Refresh SMS results, inspect possible items, and add manual entries on this phone.',
      children: quickActionRows,
    ),
  ];
  if (settingsReminderItems.isNotEmpty) {
    settingsPanels.add(const SizedBox(height: DashboardSpacing.screenBlockGap));
    settingsPanels.add(
      _SettingsGroupPanel(
        key: const ValueKey<String>('settings-reminders-panel'),
        title: 'Reminders',
        subtitle: 'Manage renewal reminders saved locally on this phone.',
        children: <Widget>[
          _SettingsNavRow(
            tileKey: const ValueKey<String>('settings-open-reminders'),
            icon: Icons.notifications_none_rounded,
            title: 'Renewal reminders',
            onTap: () => shell._showSettingsReminderManagerSheet(
              settingsReminderItems,
            ),
            trailing: Text(
              _settingsReminderSummaryLabel(activeReminderCount),
              style: Theme.of(shell.context).textTheme.labelMedium?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  settingsPanels.add(const SizedBox(height: DashboardSpacing.screenBlockGap));
  settingsPanels.add(
    const _SettingsSectionLead(
      title: 'Help & feedback',
      caption:
          'Understand the product, check privacy details, or report a problem without leaving this trust surface.',
    ),
  );
  settingsPanels.add(const SizedBox(height: 10));
  settingsPanels.add(
    _SettingsGroupPanel(
      key: const ValueKey<String>('settings-support-panel'),
      title: 'Help & privacy',
      subtitle: 'Guidance, privacy detail, and support paths.',
      children: <Widget>[
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-open-how-it-works'),
          icon: Icons.auto_awesome_outlined,
          title: 'How SubWatch works',
          onTap: shell._showHowSubWatchWorksSheet,
        ),
        const _SettingsGroupDivider(),
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-open-privacy'),
          icon: Icons.shield_outlined,
          title: 'Privacy',
          onTap: shell._showPrivacySheet,
        ),
        const _SettingsGroupDivider(),
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-report-problem'),
          icon: Icons.bug_report_outlined,
          title: 'Report a problem',
          onTap: () => shell._reportProblem(
            data: data,
            sourceStatus: sourceStatus,
            reminderItems: reminderItems,
          ),
        ),
      ],
    ),
  );
  settingsPanels.add(const SizedBox(height: DashboardSpacing.screenBlockGap));
  settingsPanels.add(
    const _SettingsSectionLead(
      title: 'Controls & recovery',
      caption:
          'Undo local decisions, check recovery history, or clear this phone view when needed.',
    ),
  );
  settingsPanels.add(const SizedBox(height: 10));
  settingsPanels.add(
    _SettingsGroupPanel(
      key: const ValueKey<String>('settings-data-panel'),
      title: 'Data & recovery',
      subtitle: 'Local recovery history and device-only cleanup actions.',
      children: <Widget>[
        if (recoveryChildren.isNotEmpty) ...<Widget>[
          ...recoveryChildren,
          const SizedBox(height: 6),
          const _SettingsGroupDivider(),
        ],
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-clear-all-data'),
          icon: Icons.delete_outline,
          title: 'Clear all data',
          subtitle: 'Remove saved data from this phone.',
          tone: DashboardSettingsRowTone.destructive,
          onTap: shell._isClearingAllData ? null : shell._confirmClearAllData,
          trailing: shell._isClearingAllData
              ? Text(
                  'Clearing...',
                  style:
                      Theme.of(shell.context).textTheme.labelMedium?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                )
              : null,
        ),
      ],
    ),
  );
  settingsPanels.add(const SizedBox(height: DashboardSpacing.screenBlockGap));
  settingsPanels.add(
    const _SettingsSectionLead(
      title: 'App info',
      caption: 'Product context and version-facing information.',
    ),
  );
  settingsPanels.add(const SizedBox(height: 10));
  settingsPanels.add(
    _SettingsGroupPanel(
      key: const ValueKey<String>('settings-about-panel'),
      title: 'About',
      subtitle: 'What SubWatch is for and what it is not.',
      children: <Widget>[
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-open-about'),
          icon: Icons.info_outline,
          title: 'About SubWatch',
          onTap: shell._showAboutSheet,
        ),
      ],
    ),
  );

  return ListView(
    key: const ValueKey<String>('destination-settings-surface'),
    padding: DashboardSpacing.secondaryScreenInset,
    children: settingsPanels,
  );
}

String _settingsReminderSummaryLabel(int activeReminderCount) {
  if (activeReminderCount <= 0) {
    return 'Off';
  }
  if (activeReminderCount == 1) {
    return '1 active';
  }
  return '$activeReminderCount active';
}

class _SettingsTrustCenterHeader extends StatelessWidget {
  const _SettingsTrustCenterHeader();

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    return DashboardPanel(
      key: const ValueKey<String>('settings-trust-center-header'),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colors.accentSoft,
          colors.paper,
        ],
      ),
      borderColor: colors.outlineStrong,
      radius: DashboardRadii.prominentCard,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              DashboardBadge(
                label: 'Trust center',
                icon: Icons.lock_outline_rounded,
                backgroundColor: DashboardShellPalette.nestedPaper,
                foregroundColor: DashboardShellPalette.softInk,
              ),
              DashboardBadge(
                label: 'On this phone',
                icon: Icons.smartphone_rounded,
                backgroundColor: DashboardShellPalette.registerPaper,
                foregroundColor: DashboardShellPalette.mutedInk,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Control the careful parts of SubWatch',
            style: type.screenTitle.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Privacy details, reminders, recovery, and product guidance are grouped here so this screen feels deliberate instead of leftover.',
            style: type.supporting.copyWith(
              color: colors.softInk,
              height: 1.34,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionLead extends StatelessWidget {
  const _SettingsSectionLead({
    required this.title,
    required this.caption,
  });

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: type.sectionTitle.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: type.supporting.copyWith(
            color: colors.mutedInk,
            height: 1.28,
          ),
        ),
      ],
    );
  }
}
