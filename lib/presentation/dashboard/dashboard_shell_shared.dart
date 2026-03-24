part of 'dashboard_shell.dart';

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    return Center(
      child: DashboardPanel(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.94, end: 1),
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0, 1),
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SubWatchBrandMark(size: 84),
              const SizedBox(height: 16),
              Text(
                'SubWatch',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preparing your view...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Loading your saved subscriptions and review items.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                    ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DashboardPanel(
          backgroundColor: DashboardShellPalette.recoverySoft,
          borderColor: const Color(0xFF435062),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.refresh_rounded,
                color: DashboardShellPalette.recovery,
                size: 28,
              ),
              const SizedBox(height: 14),
              Text(
                'Your view is not ready yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'SubWatch could not open your saved view yet. Try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                    ),
              ),
              const SizedBox(height: 14),
              _ContextualActionSemantics(
                label: 'Try again to open your saved view',
                child: FilledButton.icon(
                  key: const ValueKey<String>('retry-load-dashboard'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardLoadRecoveryNotice extends StatelessWidget {
  const _DashboardLoadRecoveryNotice({
    required this.state,
    required this.onRetry,
  });

  final DashboardLoadRecoveryState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: reduceMotion ? Duration.zero : dashboardEntranceDuration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          );
        },
        child: DashboardPanel(
          key: const ValueKey<String>('dashboard-load-recovery-notice'),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          backgroundColor: DashboardShellPalette.recoverySoft,
          borderColor: const Color(0xFF435062),
          radius: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                state.icon,
                color: DashboardShellPalette.recovery,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      state.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      state.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                            height: 1.28,
                          ),
                    ),
                  ],
                ),
              ),
              if (state.showRetryAction && onRetry != null) ...<Widget>[
                const SizedBox(width: 12),
                _ContextualActionSemantics(
                  label: 'Try again to reload your saved view',
                  child: TextButton(
                    key: const ValueKey<String>('retry-load-dashboard'),
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalsSummaryCard extends StatelessWidget {
  const _TotalsSummaryCard({
    required this.presentation,
    required this.sourceStatus,
    required this.provenance,
    required this.now,
    required this.onPrimaryAction,
  });

  final DashboardTotalsSummaryPresentation presentation;
  final RuntimeLocalMessageSourceStatus sourceStatus;
  final RuntimeSnapshotProvenance provenance;
  final DateTime now;
  final Future<void> Function()? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final hasHeroData =
        presentation.activePaidCount > 0 || presentation.hasEstimatedSpend;
    return DashboardPanel(
      key: const ValueKey<String>('totals-summary-card'),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF2E221C),
          DashboardShellPalette.paper,
        ],
      ),
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!hasHeroData) ...<Widget>[
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: DashboardShellPalette.elevatedPaper,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: DashboardShellPalette.outlineStrong,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _sourceIconForTone(sourceStatus.tone),
                    size: 44,
                    color: DashboardShellPalette.statusBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _noDataHeadline(sourceStatus),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.02,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _noDataSupportCopy(sourceStatus),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.3,
                  ),
            ),
          ] else ...<Widget>[
            Text(
              'Monthly spend',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _heroAmountLabel(),
                key: const ValueKey<String>('spend-hero-amount'),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: DashboardShellPalette.accent,
                      fontWeight: FontWeight.w800,
                      height: 0.92,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: DashboardBadge(
                key: const ValueKey<String>('spend-hero-confirmed-chip'),
                label: _confirmedChipLabel(),
                backgroundColor: DashboardShellPalette.successSoft,
                foregroundColor: DashboardShellPalette.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _lastScanLine(
                provenance,
                now: now,
              ),
              key: const ValueKey<String>('spend-hero-last-scan'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                  ),
            ),
          ],
          if (onPrimaryAction != null) ...<Widget>[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey<String>('sync-with-sms-button'),
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.sync_rounded),
                label: Text(sourceStatus.actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _heroAmountLabel() {
    if (presentation.hasEstimatedSpend) {
      return presentation.monthlyTotalValueLabel;
    }
    return 'No amount yet';
  }

  String _confirmedChipLabel() {
    if (presentation.activePaidCount == 1) {
      return '1 confirmed';
    }
    return '${presentation.activePaidCount} confirmed';
  }

  String _noDataHeadline(RuntimeLocalMessageSourceStatus status) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.caution:
        return 'Turn on SMS to discover subscriptions';
      case RuntimeLocalMessageSourceTone.restored:
        return 'Check again to discover subscriptions';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'Subscriptions appear after a scan';
      case RuntimeLocalMessageSourceTone.demo:
      case RuntimeLocalMessageSourceTone.fresh:
        return 'Scan to discover subscriptions';
    }
  }

  String _noDataSupportCopy(RuntimeLocalMessageSourceStatus status) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.caution:
        return 'SMS access required';
      case RuntimeLocalMessageSourceTone.restored:
        return 'Saved results shown';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'SMS scan unavailable here';
      case RuntimeLocalMessageSourceTone.demo:
        return 'No local scan yet';
      case RuntimeLocalMessageSourceTone.fresh:
        return 'No subscriptions found yet';
    }
  }

  String _lastScanLine(
    RuntimeSnapshotProvenance provenance, {
    required DateTime now,
  }) {
    final recordedAt = provenance.refreshedAt ?? provenance.recordedAt;
    switch (provenance.sourceKind) {
      case RuntimeSnapshotSourceKind.sampleDemo:
        return 'No scan yet';
      case RuntimeSnapshotSourceKind.deviceSms:
        return 'Last scan: ${_formatHomeStatusTimestamp(recordedAt, now: now)}';
      case RuntimeSnapshotSourceKind.safeLocalFallback:
        return 'Last scan: unavailable';
      case RuntimeSnapshotSourceKind.unknown:
        return 'Last scan: unavailable';
    }
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.accent,
    this.valueKey,
  });

  final String label;
  final String value;
  final String caption;
  final Color accent;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label. $value. $caption.',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: BoxDecoration(
            color: DashboardShellPalette.elevatedPaper.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DashboardShellPalette.outline.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                key: valueKey,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                caption,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      height: 1.24,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsetListGroup extends DashboardInsetListGroup {
  const _InsetListGroup({
    required super.children,
  });
}

class _HomeActionStrip extends StatelessWidget {
  const _HomeActionStrip({
    required this.copy,
    required this.onReview,
    required this.onSync,
    required this.onOpenRenewals,
  });

  final _HomeActionCopy copy;
  final Future<void> Function() onReview;
  final Future<void> Function() onSync;
  final Future<void> Function() onOpenRenewals;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return Container(
      key: const ValueKey<String>('home-action-strip'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: DashboardShellPalette.elevatedPaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DashboardShellPalette.outlineStrong),
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: copy.badgeBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        copy.badgeIcon,
                        size: 18,
                        color: copy.badgeForegroundColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        copy.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  key: const ValueKey<String>('home-action-primary-action'),
                  onPressed: switch (copy.primaryActionKind) {
                    _HomeActionKind.review => onReview,
                    _HomeActionKind.sync => onSync,
                    _HomeActionKind.renewals => onOpenRenewals,
                  },
                  child: Text(
                    copy.primaryActionLabel,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: copy.badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    copy.badgeIcon,
                    size: 18,
                    color: copy.badgeForegroundColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    copy.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  key: const ValueKey<String>('home-action-primary-action'),
                  onPressed: switch (copy.primaryActionKind) {
                    _HomeActionKind.review => onReview,
                    _HomeActionKind.sync => onSync,
                    _HomeActionKind.renewals => onOpenRenewals,
                  },
                  child: Text(copy.primaryActionLabel),
                ),
              ],
            ),
    );
  }
}

enum _HomeActionKind {
  review,
  renewals,
  sync,
}

class _HomeActionCopy {
  const _HomeActionCopy({
    required this.badgeLabel,
    required this.badgeIcon,
    required this.badgeBackgroundColor,
    required this.badgeForegroundColor,
    required this.title,
    required this.primaryActionKind,
    required this.primaryActionLabel,
  });

  static _HomeActionCopy? fromState({
    required RuntimeLocalMessageSourceStatus sourceStatus,
    required int reviewCount,
    required int dueSoonCount,
    required bool hasSpendHeroAction,
  }) {
    switch (sourceStatus.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return _HomeActionCopy(
          badgeLabel: 'Sample view',
          badgeIcon: Icons.sms_outlined,
          badgeBackgroundColor: DashboardShellPalette.cautionSoft,
          badgeForegroundColor: DashboardShellPalette.caution,
          title: 'Scan your messages',
          primaryActionKind: _HomeActionKind.sync,
          primaryActionLabel: sourceStatus.actionLabel,
        );
      case RuntimeLocalMessageSourceTone.caution:
        return _HomeActionCopy(
          badgeLabel: 'Action needed',
          badgeIcon: Icons.sms_failed_outlined,
          badgeBackgroundColor: DashboardShellPalette.cautionSoft,
          badgeForegroundColor: DashboardShellPalette.caution,
          title: 'Turn on SMS access',
          primaryActionKind: _HomeActionKind.sync,
          primaryActionLabel: sourceStatus.actionLabel,
        );
      case RuntimeLocalMessageSourceTone.restored:
        return _HomeActionCopy(
          badgeLabel: 'Saved view',
          badgeIcon: Icons.history_toggle_off_rounded,
          badgeBackgroundColor: DashboardShellPalette.recoverySoft,
          badgeForegroundColor: DashboardShellPalette.recovery,
          title: 'Check again',
          primaryActionKind: _HomeActionKind.sync,
          primaryActionLabel: sourceStatus.actionLabel,
        );
      case RuntimeLocalMessageSourceTone.fresh:
        if (reviewCount > 0) {
          return _reviewState(reviewCount);
        }
        if (dueSoonCount > 0) {
          return _renewalState(dueSoonCount);
        }
        return null;
      case RuntimeLocalMessageSourceTone.unavailable:
        return null;
    }
  }

  static _HomeActionCopy _reviewState(int reviewCount) {
    return _HomeActionCopy(
      badgeLabel: 'Needs review',
      badgeIcon: Icons.rule_folder_outlined,
      badgeBackgroundColor: DashboardShellPalette.cautionSoft,
      badgeForegroundColor: DashboardShellPalette.caution,
      title: reviewCount == 1 ? '1 item waiting' : '$reviewCount items waiting',
      primaryActionKind: _HomeActionKind.review,
      primaryActionLabel: reviewCount == 1 ? 'Review item' : 'Review items',
    );
  }

  static _HomeActionCopy _renewalState(int dueSoonCount) {
    return _HomeActionCopy(
      badgeLabel: 'Due soon',
      badgeIcon: Icons.schedule_outlined,
      badgeBackgroundColor: DashboardShellPalette.cautionSoft,
      badgeForegroundColor: DashboardShellPalette.caution,
      title: dueSoonCount == 1
          ? '1 renewal coming up'
          : '$dueSoonCount renewals coming up',
      primaryActionKind: _HomeActionKind.renewals,
      primaryActionLabel: 'View renewals',
    );
  }

  final String badgeLabel;
  final IconData badgeIcon;
  final Color badgeBackgroundColor;
  final Color badgeForegroundColor;
  final String title;
  final _HomeActionKind primaryActionKind;
  final String primaryActionLabel;
}

class _HomeRenewalsZoneCard extends StatelessWidget {
  const _HomeRenewalsZoneCard({
    required this.dueSoon,
    required this.upcomingRenewals,
    required this.reminderItems,
  });

  final DashboardDueSoonPresentation dueSoon;
  final DashboardUpcomingRenewalsPresentation upcomingRenewals;
  final List<DashboardRenewalReminderItemPresentation> reminderItems;

  @override
  Widget build(BuildContext context) {
    final dueSoonServiceKeys =
        dueSoon.items.map((item) => item.serviceKey).toSet();
    final laterRenewals = reminderItems
        .where((item) => !dueSoonServiceKeys.contains(item.renewal.serviceKey))
        .toList(growable: false);
    final visibleUpcomingItems =
        dueSoon.hasItems ? laterRenewals : reminderItems;

    return DashboardPanel(
      key: const ValueKey<String>('home-renewals-zone'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: DashboardSectionFrame(
        title: 'Renewals',
        children: <Widget>[
          if (dueSoon.hasItems) ...<Widget>[
            Text(
              'Due soon',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: DashboardShellPalette.caution,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: const ValueKey<String>('due-soon-card'),
              child: _InsetListGroup(
                children: dueSoon.items
                    .map(
                      (item) => _RenewalItemTile(
                        key: ValueKey<String>(
                          'due-soon-item-${item.serviceTitle}',
                        ),
                        item: item,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (visibleUpcomingItems.isNotEmpty) ...<Widget>[
            if (dueSoon.hasItems) ...<Widget>[
              const SizedBox(height: 12),
              const Divider(color: DashboardShellPalette.outline),
              const SizedBox(height: 12),
            ],
            Text(
              dueSoon.hasItems ? 'Later' : 'Upcoming renewals',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: const ValueKey<String>('upcoming-renewals-card'),
              child: _InsetListGroup(
                children: visibleUpcomingItems
                    .map(
                      (item) => _RenewalItemTile(
                        key: ValueKey<String>(
                          'upcoming-renewal-item-${item.renewal.serviceTitle}',
                        ),
                        item: item.renewal,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingRenewalsCard extends StatelessWidget {
  const _UpcomingRenewalsCard({
    required this.presentation,
    required this.reminderItems,
    required this.showReminderControls,
    required this.onOpenReminderControls,
    required this.reminderTargetsInFlight,
  });

  final DashboardUpcomingRenewalsPresentation presentation;
  final List<DashboardRenewalReminderItemPresentation> reminderItems;
  final bool showReminderControls;
  final ValueChanged<DashboardRenewalReminderItemPresentation>
      onOpenReminderControls;
  final Set<String> reminderTargetsInFlight;

  @override
  Widget build(BuildContext context) {
    final countLabel = presentation.hasItems
        ? presentation.items.length == 1
            ? '1 date'
            : '${presentation.items.length} dates'
        : null;

    return Column(
      key: const ValueKey<String>('upcoming-renewals-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DashboardSectionFrame(
          title: 'Upcoming renewals',
          caption: presentation.summaryCopy,
          countLabel: countLabel,
          children: <Widget>[
            if (!presentation.hasItems)
              _EmptySectionText(
                title: presentation.emptyTitle,
                message: presentation.emptyMessage,
                icon: Icons.event_repeat_outlined,
              )
            else
              _InsetListGroup(
                children: reminderItems
                    .map(
                      (item) => _ReminderRenewalItemTile(
                        key: ValueKey<String>(
                          'upcoming-renewal-item-${item.renewal.serviceTitle}',
                        ),
                        item: item,
                        isBusy: reminderTargetsInFlight.contains(
                          item.renewal.serviceKey,
                        ),
                        showReminderControls: showReminderControls,
                        onOpenReminderControls:
                            showReminderControls && item.canConfigureReminder
                                ? () => onOpenReminderControls(item)
                                : null,
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ],
    );
  }
}

class _DueSoonCard extends StatelessWidget {
  const _DueSoonCard({
    required this.presentation,
  });

  final DashboardDueSoonPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final countLabel = presentation.hasItems
        ? presentation.items.length == 1
            ? '1 renewal'
            : '${presentation.items.length} renewals'
        : null;

    return Column(
      key: const ValueKey<String>('due-soon-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DashboardSectionFrame(
          title: 'Due soon',
          caption: presentation.summaryCopy,
          countLabel: countLabel,
          children: <Widget>[
            if (!presentation.hasItems)
              _EmptySectionText(
                title: presentation.emptyTitle,
                message: presentation.emptyMessage,
                icon: Icons.schedule_outlined,
              )
            else
              _InsetListGroup(
                children: presentation.items
                    .map(
                      (item) => _RenewalItemTile(
                        key: ValueKey<String>(
                          'due-soon-item-${item.serviceTitle}',
                        ),
                        item: item,
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ],
    );
  }
}

class _RenewalItemTile extends StatelessWidget {
  const _RenewalItemTile({
    super.key,
    required this.item,
  });

  final DashboardUpcomingRenewalItemPresentation item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.serviceTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.renewalDateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                      ),
                ),
              ],
            ),
          ),
          if (item.amountLabel != null)
            DashboardBadge(
              label: item.amountLabel!,
              backgroundColor: DashboardShellPalette.paper,
              foregroundColor: DashboardShellPalette.statusBlue,
            ),
        ],
      ),
    );
  }
}

class _ReminderRenewalItemTile extends StatelessWidget {
  const _ReminderRenewalItemTile({
    super.key,
    required this.item,
    required this.isBusy,
    this.showReminderControls = true,
    required this.onOpenReminderControls,
  });

  final DashboardRenewalReminderItemPresentation item;
  final bool isBusy;
  final bool showReminderControls;
  final VoidCallback? onOpenReminderControls;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.renewal.serviceTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.renewal.renewalDateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.statusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                          ),
                    ),
                  ],
                ),
              ),
              if (item.renewal.amountLabel != null)
                DashboardBadge(
                  label: item.renewal.amountLabel!,
                  backgroundColor: DashboardShellPalette.paper,
                  foregroundColor: DashboardShellPalette.statusBlue,
                ),
            ],
          ),
          if (showReminderControls) ...<Widget>[
            const SizedBox(height: 6),
            TextButton.icon(
              key: ValueKey<String>(
                'open-renewal-reminder-controls-${item.renewal.serviceKey}',
              ),
              onPressed: isBusy ? null : onOpenReminderControls,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Reminder'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionCardMetadata {
  const _SubscriptionCardMetadata({
    required this.amountLabel,
    required this.renewalLabel,
    required this.frequencyLabel,
    this.bundledSummary,
  });

  factory _SubscriptionCardMetadata.fromCard(
    DashboardCard card, {
    DashboardUpcomingRenewalItemPresentation? renewal,
  }) {
    return _SubscriptionCardMetadata(
      amountLabel: card.amountLabel ?? _fallbackAmountLabel(card.bucket),
      renewalLabel:
          renewal?.renewalDateLabel ?? _fallbackRenewalLabel(card.bucket),
      frequencyLabel:
          card.frequencyLabel ?? _fallbackFrequencyLabel(card.bucket),
      bundledSummary: card.bucket == DashboardBucket.trialsAndBenefits
          ? 'Bundled with another plan - no separate charge.'
          : null,
    );
  }

  final String amountLabel;
  final String renewalLabel;
  final String frequencyLabel;
  final String? bundledSummary;
}

class _SubscriptionInfoChip extends StatelessWidget {
  const _SubscriptionInfoChip({
    required this.valueKey,
    required this.title,
    required this.value,
    required this.width,
  });

  final Key valueKey;
  final String title;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $value',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: width),
          child: Container(

            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: DashboardShellPalette.nestedPaper.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DashboardShellPalette.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.18,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  key: valueKey,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionMetaPanel extends StatelessWidget {
  const _SubscriptionMetaPanel({
    required this.amountValueKey,
    required this.amountLabel,
    required this.renewalValueKey,
    required this.renewalLabel,
    this.summaryValueKey,
    this.bundledSummary,
  });

  final Key amountValueKey;
  final String amountLabel;
  final Key renewalValueKey;
  final String renewalLabel;
  final Key? summaryValueKey;
  final String? bundledSummary;

  @override
  Widget build(BuildContext context) {
    if (bundledSummary != null) {
      return Semantics(
        label: bundledSummary!,
        child: ExcludeSemantics(
          child: Text(
            bundledSummary!,
            key: summaryValueKey,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  fontWeight: FontWeight.w600,
                  height: 1.24,
                ),
          ),
        ),
      );
    }

    return Semantics(
      label:
          'Amount: $amountLabel. Next renewal: ${_subscriptionCardDueLabel(renewalLabel)}',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 6,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              amountLabel,
              key: amountValueKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: DashboardShellPalette.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
            ),
            Text(
              '\u00b7',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              _subscriptionCardDueLabel(renewalLabel),
              key: renewalValueKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    fontWeight: FontWeight.w600,
                    height: 1.18,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineCardStatus extends StatelessWidget {
  const _InlineCardStatus({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _SubscriptionListRow extends StatelessWidget {
  const _SubscriptionListRow({
    super.key,
    required this.card,
    required this.metadata,
    required this.style,
    required this.servicePresentationState,
    required this.onTap,
    required this.trailing,
  });

  final DashboardCard card;
  final _SubscriptionCardMetadata metadata;
  final _BucketStyle style;
  final LocalServicePresentationState servicePresentationState;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final displayTitle = servicePresentationState.displayTitle;
    final identity = _identityStyle(
      displayTitle,
      accentColor: style.badgeForeground,
    );
    final summary = _subscriptionRowSemantics(
      card,
      metadata: metadata,
      style: style,
      servicePresentationState: servicePresentationState,
    );

    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Semantics(
              key: ValueKey<String>(
                'subscription-row-semantics-${card.serviceKey.value}',
              ),
              button: true,
              label: summary,
              hint: 'Opens service details',
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  splashColor: style.badgeForeground.withValues(alpha: 0.08),
                  highlightColor: style.badgeForeground.withValues(alpha: 0.04),
                  hoverColor: style.badgeForeground.withValues(alpha: 0.03),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 0, 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DashboardServiceAvatar(
                          key:
                              ValueKey<String>('passport-avatar-${card.title}'),
                          monogram: identity.monogram,
                          foregroundColor: identity.foreground,
                          backgroundColor: identity.background,
                          borderColor: identity.border,
                          serviceKey: card.serviceKey.value,
                          sealColor: style.badgeForeground,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Builder(
                                builder: (context) {
                                  final stackedTitle = MediaQuery.sizeOf(context).width < 380 ||
                                      MediaQuery.textScalerOf(context).scale(1) > 1.15;
                                  final title = Text(
                                    displayTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  );
                                  final badge = DashboardBadge(
                                    label: style.badgeLabel,
                                    backgroundColor: style.badgeBackground,
                                    foregroundColor: style.badgeForeground,
                                  );

                                  if (stackedTitle) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        title,
                                        const SizedBox(height: 5),
                                        badge,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(child: title),
                                      const SizedBox(width: 8),
                                      badge,
                                    ],
                                  );
                                },
                              ),
                              if (servicePresentationState
                                  .hasLocalLabel) ...<Widget>[
                                const SizedBox(height: 2),
                                Text(
                                  servicePresentationState.originalTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: DashboardShellPalette.mutedInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                card.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              if (servicePresentationState.isPinned ||
                                  servicePresentationState
                                      .hasLocalLabel) ...<Widget>[
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    if (servicePresentationState.isPinned)
                                      const _InlineCardStatus(
                                        icon: Icons.push_pin_rounded,
                                        label: 'Pinned on this phone',
                                        color: DashboardShellPalette.statusBlue,
                                      ),
                                    if (servicePresentationState.hasLocalLabel)
                                      const _InlineCardStatus(
                                        icon: Icons.edit_note_rounded,
                                        label: 'Custom label',
                                        color: DashboardShellPalette.mutedInk,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              _SubscriptionMetaPanel(
                                amountValueKey: ValueKey<String>(
                                  'subscription-meta-amount-${card.serviceKey.value}',
                                ),
                                amountLabel: metadata.amountLabel,
                                renewalValueKey: ValueKey<String>(
                                  'subscription-meta-renewal-${card.serviceKey.value}',
                                ),
                                renewalLabel: metadata.renewalLabel,
                                summaryValueKey: ValueKey<String>(
                                  'subscription-meta-summary-${card.serviceKey.value}',
                                ),
                                bundledSummary: metadata.bundledSummary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 11, 8, 11),
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionDetailsSheet extends StatelessWidget {
  const _SubscriptionDetailsSheet({
    required this.card,
    required this.bucket,
    required this.servicePresentationState,
    required this.metadata,
    this.renewal,
    required this.onExplain,
    required this.onOpenLocalServiceControls,
    required this.onOpenRenewalReminderControls,
  });

  final DashboardCard card;
  final DashboardBucket bucket;
  final LocalServicePresentationState servicePresentationState;
  final _SubscriptionCardMetadata metadata;
  final DashboardUpcomingRenewalItemPresentation? renewal;
  final VoidCallback onExplain;
  final VoidCallback onOpenLocalServiceControls;
  final VoidCallback? onOpenRenewalReminderControls;

  @override
  Widget build(BuildContext context) {
    final style = switch (bucket) {
      DashboardBucket.confirmedSubscriptions => const _BucketStyle(
          badgeLabel: 'Confirmed',
          background: DashboardShellPalette.successSoft,
          border: Color(0xFF355344),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.success,
        ),
      DashboardBucket.needsReview => const _BucketStyle(
          badgeLabel: 'Needs review',
          background: DashboardShellPalette.elevatedPaper,
          border: DashboardShellPalette.outlineStrong,
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.mutedInk,
        ),
      DashboardBucket.trialsAndBenefits => const _BucketStyle(
          badgeLabel: 'Separate access',
          background: Color(0xFF18211C),
          border: Color(0xFF314339),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.benefitGold,
        ),
      DashboardBucket.hidden => const _BucketStyle(
          badgeLabel: 'Hidden',
          background: DashboardShellPalette.recoverySoft,
          border: Color(0xFF394556),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.recovery,
        ),
    };
    final identity =
        _identityStyle(card.title, accentColor: style.badgeForeground);
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
              'subscription-details-sheet-${card.serviceKey.value}'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SheetHandle(),
              const SizedBox(height: 10),
              if (stackedHeader)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DashboardServiceAvatar(
                          monogram: identity.monogram,
                          foregroundColor: identity.foreground,
                          backgroundColor: identity.background,
                          borderColor: identity.border,
                          serviceKey: card.serviceKey.value,
                          sealColor: style.badgeForeground,
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                card.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DashboardServiceAvatar(
                      monogram: identity.monogram,
                      foregroundColor: identity.foreground,
                      backgroundColor: identity.background,
                      borderColor: identity.border,
                      serviceKey: card.serviceKey.value,
                      sealColor: style.badgeForeground,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            card.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  DashboardBadge(
                    label: style.badgeLabel,
                    backgroundColor: style.badgeBackground,
                    foregroundColor: style.badgeForeground,
                  ),
                  if (servicePresentationState.isPinned)
                    const DashboardBadge(
                      label: 'Pinned',
                      backgroundColor: DashboardShellPalette.paper,
                      foregroundColor: DashboardShellPalette.statusBlue,
                    ),
                  if (servicePresentationState.hasLocalLabel)
                    const DashboardBadge(
                      label: 'Custom label',
                      backgroundColor: DashboardShellPalette.paper,
                      foregroundColor: DashboardShellPalette.ink,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _SubscriptionInfoChip(
                    valueKey: ValueKey<String>(
                      'subscription-details-meta-amount-${card.serviceKey.value}',
                    ),
                    title: 'Amount',
                    value: metadata.amountLabel,
                    width: 148,
                  ),
                  _SubscriptionInfoChip(
                    valueKey: ValueKey<String>(
                      'subscription-details-meta-renewal-${card.serviceKey.value}',
                    ),
                    title: 'Next renewal',
                    value: metadata.renewalLabel,
                    width: 148,
                  ),
                  _SubscriptionInfoChip(
                    valueKey: ValueKey<String>(
                      'subscription-details-meta-frequency-${card.serviceKey.value}',
                    ),
                    title: 'Frequency',
                    value: metadata.frequencyLabel,
                    width: 148,
                  ),
                ],
              ),
              if (servicePresentationState.hasLocalLabel ||
                  servicePresentationState.originalTitle !=
                      card.title) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Original name',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  servicePresentationState.originalTitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 14),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExplain,
                      child: const Text('Why this'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpenLocalServiceControls,
                      child: const Text('Manage device'),
                    ),
                  ),
                ],
              ),
              if (onOpenRenewalReminderControls != null) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: ValueKey<String>(
                      'details-open-renewal-reminder-controls-${card.serviceKey.value}',
                    ),
                    onPressed: onOpenRenewalReminderControls,
                    icon: const Icon(Icons.alarm_rounded),
                    label: const Text('Set local reminder'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncProgressPresentation {
  const _SyncProgressPresentation({
    required this.title,
    required this.description,
  });

  factory _SyncProgressPresentation.fromElapsed(Duration elapsed) {
    if (elapsed >= const Duration(seconds: 5)) {
      return const _SyncProgressPresentation(
        title: 'Still working through a larger message history',
        description: 'SubWatch is still sorting paid, review, and benefit items.',
      );
    }
    if (elapsed >= const Duration(seconds: 2)) {
      return const _SyncProgressPresentation(
        title: 'Sorting confirmed, review, and benefit items',
        description: 'SubWatch is separating strong paid signals from the rest.',
      );
    }
    return const _SyncProgressPresentation(
      title: 'Scanning messages on this phone',
      description: 'SubWatch is checking your messages for recurring billing.',
    );
  }

  final String title;
  final String description;
}

class _SourceStatusCard extends StatelessWidget {
  const _SourceStatusCard({
    required this.status,
    required this.isSyncing,
    required this.syncElapsed,
    required this.onSync,
    required this.onExplain,
  });

  final RuntimeLocalMessageSourceStatus status;
  final bool isSyncing;
  final ValueNotifier<Duration> syncElapsed;
  final Future<void> Function() onSync;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    return ValueListenableBuilder<Duration>(
      valueListenable: syncElapsed,
      builder: (context, elapsed, child) {
        final syncProgress = _SyncProgressPresentation.fromElapsed(elapsed);
        final title = isSyncing ? 'Checking device SMS' : status.title;
        final description = isSyncing
            ? 'Building your local view. Nothing leaves your phone.'
            : status.description;

        final actionLabel = isSyncing ? 'Checking SMS...' : status.actionLabel;

        return LayoutBuilder(
          builder: (context, constraints) {
            final useStackedAction = constraints.maxWidth < 360;
            final actionButton = FilledButton.icon(
              key: const ValueKey<String>('sync-with-sms-button'),
              onPressed: isSyncing || !status.isActionEnabled ? null : onSync,
              icon: Icon(
                isSyncing ? Icons.hourglass_top : Icons.sync_rounded,
              ),
              label: Text(actionLabel),
            );

            return Container(
              key: const ValueKey<String>('snapshot-certificate-card'),
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: BoxDecoration(
                color: DashboardShellPalette.paper.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: DashboardShellPalette.outline.withValues(alpha: 0.72),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (useStackedAction) ...<Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: actionButton,
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        actionButton,
                      ],
                    ),
                  if (!isSyncing &&
                      status.tone ==
                          RuntimeLocalMessageSourceTone.demo) ...<Widget>[
                    const SizedBox(height: 10),
                    DashboardPanel(
                      key: const ValueKey<String>('sample-data-banner'),
                      backgroundColor:
                          DashboardShellPalette.registerPaper.withValues(
                        alpha: 0.94,
                      ),
                      borderColor: DashboardShellPalette.statusBlue,
                      radius: 16,
                      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: DashboardShellPalette.statusBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Example data only. Scan your messages to see your subscriptions.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DashboardShellPalette.ink,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isSyncing) ...<Widget>[
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : dashboardMotionDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) {
                        final position = Tween<Offset>(
                          begin: const Offset(0, -0.04),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: position,
                            child: child,
                          ),
                        );
                      },
                      child: DashboardPanel(
                        key: const ValueKey<String>('sync-progress-panel'),
                        backgroundColor: DashboardShellPalette.elevatedPaper,
                        borderColor: DashboardShellPalette.outlineStrong,
                        radius: 16,
                        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                const DashboardBadge(
                                  label: 'On-device scan',
                                  backgroundColor: DashboardShellPalette.paper,
                                  foregroundColor:
                                      DashboardShellPalette.statusBlue,
                                ),
                                Text(
                                  'Runs only on this phone',
                                  key: const ValueKey<String>(
                                    'sync-progress-privacy-label',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: DashboardShellPalette.mutedInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                key:
                                    ValueKey<String>('sync-progress-indicator'),
                                minHeight: 6,
                                backgroundColor:
                                    DashboardShellPalette.nestedPaper,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  DashboardShellPalette.statusBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : dashboardMotionDuration,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Text(
                                syncProgress.title,
                                key: ValueKey<String>(
                                  'sync-progress-title-${syncProgress.title}',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : dashboardMotionDuration,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Text(
                                syncProgress.description,
                                key: ValueKey<String>(
                                  'sync-progress-description-${syncProgress.description}',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You can keep browsing while this scan finishes.',
                              key: ValueKey<String>('sync-progress-hint'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    status.provenanceDescription,
                    key: const ValueKey<String>(
                        'runtime-provenance-description'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _SourceStatusMetadataCluster(status: status),
                      TextButton(
                        key: const ValueKey<String>(
                            'open-snapshot-explanation-button'),
                        onPressed: onExplain,
                        child: const Text('Why this view'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductGuidancePanel extends StatelessWidget {
  const _ProductGuidancePanel({
    required this.completion,
    required this.samplePreview,
    required this.onPrimaryAction,
    required this.onOpenTrustSheet,
  });

  final DashboardCompletionPresentation completion;
  final _SampleHomePreviewState? samplePreview;
  final Future<void> Function()? onPrimaryAction;
  final VoidCallback? onOpenTrustSheet;

  @override
  Widget build(BuildContext context) {
    if (samplePreview != null) {
      final stackedPreviewHeader = MediaQuery.sizeOf(context).width < 360 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.1;
      final stackedPreviewMetrics = MediaQuery.sizeOf(context).width < 360 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.08;
      return DashboardPanel(
        key: const ValueKey<String>('product-guidance-panel'),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF9F2E8),
            DashboardShellPalette.paper,
          ],
        ),
        borderColor: const Color(0xFF7F654D),
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                DashboardBadge(
                  label: completion.eyebrow,
                  icon: Icons.auto_awesome_outlined,
                  backgroundColor: DashboardShellPalette.registerPaper,
                  foregroundColor: DashboardShellPalette.statusBlue,
                ),
                const DashboardBadge(
                  label: 'Sample data only',
                  icon: Icons.visibility_outlined,
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  foregroundColor: DashboardShellPalette.mutedInk,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (stackedPreviewHeader)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SubWatchBrandMark(size: 48, showBase: true),
                  const SizedBox(height: 10),
                  Text(
                    completion.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    completion.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          height: 1.32,
                        ),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          completion.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          completion.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                    height: 1.32,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SubWatchBrandMark(size: 54, showBase: true),
                ],
              ),
            const SizedBox(height: 14),
            if (stackedPreviewMetrics)
              Column(
                children: <Widget>[
                  _CompactMetricTile(
                    label: 'Monthly spend estimate',
                    value: samplePreview!.monthlyTotalLabel,
                    caption: samplePreview!.monthlyTotalCaption,
                    accent: DashboardShellPalette.statusBlue,
                  ),
                  const SizedBox(height: 8),
                  _CompactMetricTile(
                    label: 'Confirmed',
                    value: samplePreview!.confirmedCountLabel,
                    caption: 'Paid subscriptions',
                    accent: DashboardShellPalette.success,
                  ),
                  const SizedBox(height: 8),
                  _CompactMetricTile(
                    label: 'Needs review',
                    value: samplePreview!.reviewCountLabel,
                    caption: 'Kept separate',
                    accent: DashboardShellPalette.caution,
                  ),
                  const SizedBox(height: 8),
                  _CompactMetricTile(
                    label: 'Trials & benefits',
                    value: samplePreview!.trialCountLabel,
                    caption: 'Separate access',
                    accent: DashboardShellPalette.benefitGold,
                  ),
                ],
              )
            else ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Monthly spend estimate',
                      value: samplePreview!.monthlyTotalLabel,
                      caption: samplePreview!.monthlyTotalCaption,
                      accent: DashboardShellPalette.statusBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Confirmed',
                      value: samplePreview!.confirmedCountLabel,
                      caption: 'Paid subscriptions',
                      accent: DashboardShellPalette.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Needs review',
                      value: samplePreview!.reviewCountLabel,
                      caption: 'Kept separate',
                      accent: DashboardShellPalette.caution,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Trials & benefits',
                      value: samplePreview!.trialCountLabel,
                      caption: 'Separate access',
                      accent: DashboardShellPalette.benefitGold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            DashboardPanel(
              key: const ValueKey<String>('sample-preview-details-panel'),
              backgroundColor: DashboardShellPalette.elevatedPaper,
              borderColor: DashboardShellPalette.outline,
              radius: 20,
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'What this sample preview shows',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _InsetListGroup(
                    children: samplePreview!.highlights
                        .map(
                          (highlight) => _SamplePreviewHighlightRow(
                            highlight: highlight,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              completion.bullets[1],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.28,
                  ),
            ),
            if (onOpenTrustSheet != null) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey<String>(
                      'product-guidance-open-trust-sheet'),
                  onPressed: onOpenTrustSheet,
                  child: Text(completion.learnMoreActionLabel),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      key: const ValueKey<String>('product-guidance-panel'),
      child: DashboardPanel(
        backgroundColor: DashboardShellPalette.elevatedPaper,
        borderColor: DashboardShellPalette.outline,
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (completion.eyebrow.isNotEmpty) ...<Widget>[
              DashboardBadge(
                label: completion.eyebrow,
                icon: Icons.info_outline_rounded,
                backgroundColor: DashboardShellPalette.paper,
                foregroundColor: DashboardShellPalette.statusBlue,
              ),
              const SizedBox(height: 10),
            ],
            Text(
              completion.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              completion.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.28,
                  ),
            ),
            if (completion.bullets.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              _InsetListGroup(
                children: completion.bullets
                    .map(
                      (bullet) => Padding(
                        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: DashboardShellPalette.statusBlue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bullet,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.ink,
                                      height: 1.24,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (onPrimaryAction != null ||
                onOpenTrustSheet != null) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  if (onPrimaryAction != null)
                    FilledButton(
                      key: const ValueKey<String>(
                        'product-guidance-primary-action',
                      ),
                      onPressed: () {
                        onPrimaryAction!();
                      },
                      child: Text(completion.primaryActionLabel),
                    ),
                  if (onOpenTrustSheet != null)
                    TextButton(
                      key: const ValueKey<String>(
                        'product-guidance-open-trust-sheet',
                      ),
                      onPressed: onOpenTrustSheet,
                      child: Text(completion.learnMoreActionLabel),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SampleHomePreviewState {
  const _SampleHomePreviewState({
    required this.monthlyTotalLabel,
    required this.monthlyTotalCaption,
    required this.confirmedCountLabel,
    required this.reviewCountLabel,
    required this.trialCountLabel,
    required this.highlights,
  });

  factory _SampleHomePreviewState.fromSnapshot(
    RuntimeDashboardSnapshot snapshot, {
    required DashboardTotalsSummaryPresentation totalsSummary,
    required DashboardDueSoonPresentation dueSoon,
  }) {
    final confirmedCards = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.confirmedSubscriptions)
        .toList(growable: false);
    final trialCards = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
        .toList(growable: false);
    final reviewItems = snapshot.reviewQueue;

    final confirmedTitles = confirmedCards
        .map((card) => card.title)
        .where((title) => title.trim().isNotEmpty)
        .toList(growable: false);
    final reviewTitles = reviewItems
        .map((item) => item.title)
        .where((title) => title.trim().isNotEmpty)
        .toList(growable: false);
    final trialTitles = trialCards
        .map((card) => card.title)
        .where((title) => title.trim().isNotEmpty)
        .toList(growable: false);

    return _SampleHomePreviewState(
      monthlyTotalLabel: totalsSummary.monthlyTotalValueLabel,
      monthlyTotalCaption: totalsSummary.includedInMonthlyTotalCount == 0
          ? 'Example once billed amounts are visible'
          : 'Example from ${totalsSummary.includedInMonthlyTotalCount} paid renewals',
      confirmedCountLabel: confirmedCards.length.toString(),
      reviewCountLabel: reviewItems.length.toString(),
      trialCountLabel: trialCards.length.toString(),
      highlights: <_SamplePreviewHighlight>[
        _SamplePreviewHighlight(
          icon: Icons.verified_rounded,
          title: 'Confirmed subscriptions',
          badgeLabel: _previewCountLabel(confirmedCards.length),
          description: confirmedTitles.isEmpty
              ? 'Paid subscriptions appear here when billing evidence is strong enough.'
              : '${_joinPreviewTitles(confirmedTitles)} appear as paid subscriptions here.',
        ),
        _SamplePreviewHighlight(
          icon: Icons.schedule_rounded,
          title: 'Due soon',
          badgeLabel: dueSoon.hasItems ? 'Shown in preview' : 'Preview example',
          description: dueSoon.hasItems
              ? _dueSoonPreviewDescription(
                  dueSoon.items.first.serviceTitle,
                  dueSoon.items.first.renewalDateLabel,
                  dueSoon.items.first.amountLabel,
                )
              : _demoDueSoonFallback(
                  confirmedCards,
                  snapshot.provenance.recordedAt,
                ),
        ),
        _SamplePreviewHighlight(
          icon: Icons.rule_folder_outlined,
          title: 'Needs review',
          badgeLabel: _previewCountLabel(reviewItems.length),
          description: reviewTitles.isEmpty
              ? 'Unclear recurring signals stay separate until you decide.'
              : '${_joinPreviewTitles(reviewTitles)} stay separate until you decide.',
        ),
        _SamplePreviewHighlight(
          icon: Icons.workspace_premium_outlined,
          title: 'Trials & benefits',
          badgeLabel: _previewCountLabel(trialCards.length),
          description: trialTitles.isEmpty
              ? 'Bundled access stays visible without being counted as paid.'
              : '${trialTitles.first} stays visible as separate access.',
        ),
      ],
    );
  }

  final String monthlyTotalLabel;
  final String monthlyTotalCaption;
  final String confirmedCountLabel;
  final String reviewCountLabel;
  final String trialCountLabel;
  final List<_SamplePreviewHighlight> highlights;
}

class _SamplePreviewHighlight {
  const _SamplePreviewHighlight({
    required this.icon,
    required this.title,
    required this.badgeLabel,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String badgeLabel;
  final String description;
}

class _SamplePreviewHighlightRow extends StatelessWidget {
  const _SamplePreviewHighlightRow({
    required this.highlight,
  });

  final _SamplePreviewHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final stackedHeader = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.08;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DashboardShellPalette.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DashboardShellPalette.outline.withValues(alpha: 0.7),
              ),
            ),
            child: Icon(
              highlight.icon,
              size: 18,
              color: DashboardShellPalette.statusBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        highlight.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      DashboardBadge(
                        label: highlight.badgeLabel,
                        backgroundColor: DashboardShellPalette.paper,
                        foregroundColor: DashboardShellPalette.mutedInk,
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          highlight.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      DashboardBadge(
                        label: highlight.badgeLabel,
                        backgroundColor: DashboardShellPalette.paper,
                        foregroundColor: DashboardShellPalette.mutedInk,
                      ),
                    ],
                  ),
                const SizedBox(height: 3),
                Text(
                  highlight.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        height: 1.28,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeroConfirmedRescuePanel extends StatelessWidget {
  const _ZeroConfirmedRescuePanel({
    required this.completion,
    required this.rescueState,
    required this.onOpenReview,
    required this.onOpenSubscriptions,
    required this.onAddManually,
    required this.onOpenTrustSheet,
  });

  final DashboardCompletionPresentation completion;
  final _ZeroConfirmedRescueState rescueState;
  final Future<void> Function() onOpenReview;
  final Future<void> Function() onOpenSubscriptions;
  final Future<void> Function() onAddManually;
  final VoidCallback onOpenTrustSheet;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      key: const ValueKey<String>('home-zero-confirmed-rescue'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DashboardBadge(
            label: completion.eyebrow,
            icon: Icons.verified_outlined,
            backgroundColor: DashboardShellPalette.successSoft,
            foregroundColor: DashboardShellPalette.success,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              DashboardBadge(
                label: rescueState.sourceLabel,
                icon: rescueState.sourceIcon,
                backgroundColor: DashboardShellPalette.elevatedPaper,
                foregroundColor: DashboardShellPalette.ink,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            completion.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            completion.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  height: 1.28,
                ),
          ),
          const SizedBox(height: 12),
          DashboardPanel(
            key: const ValueKey<String>('home-zero-confirmed-education'),
            backgroundColor: DashboardShellPalette.elevatedPaper,
            borderColor: DashboardShellPalette.outline,
            radius: 20,
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  rescueState.explanationTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  rescueState.explanationBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.ink,
                        height: 1.28,
                      ),
                ),
                if (rescueState.supportingExplanationBody != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    rescueState.supportingExplanationBody!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          height: 1.28,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (rescueState.visibleFindings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            DashboardPanel(
              key: const ValueKey<String>('home-zero-confirmed-findings'),
              backgroundColor: DashboardShellPalette.elevatedPaper,
              borderColor: DashboardShellPalette.outline,
              radius: 20,
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'What stayed visible',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ..._buildFindingRows(),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'What you can do next',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              FilledButton(
                key: const ValueKey<String>('zero-confirmed-primary-action'),
                onPressed: switch (rescueState.primaryActionKind) {
                  _ZeroConfirmedPrimaryActionKind.review => onOpenReview,
                  _ZeroConfirmedPrimaryActionKind.subscriptions =>
                    onOpenSubscriptions,
                  _ZeroConfirmedPrimaryActionKind.manualAdd => onAddManually,
                },
                child: Text(rescueState.primaryActionLabel),
              ),
              if (rescueState.primaryActionKind !=
                  _ZeroConfirmedPrimaryActionKind.manualAdd)
                OutlinedButton(
                  key: const ValueKey<String>(
                      'zero-confirmed-add-manually-action'),
                  onPressed: onAddManually,
                  child: const Text('Add manually'),
                ),
              TextButton(
                key: const ValueKey<String>('zero-confirmed-secondary-action'),
                onPressed: onOpenTrustSheet,
                child: const Text('Why the list is still empty'),
              ),
            ],
          ),
          if (rescueState.actionHint != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              rescueState.actionHint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.28,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFindingRows() {
    return rescueState.visibleFindings
        .map(
          (summary) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ZeroConfirmedFindingRow(summary: summary),
          ),
        )
        .toList(growable: false);
  }
}

class _ZeroConfirmedRescueState {
  const _ZeroConfirmedRescueState({
    required this.sourceLabel,
    required this.sourceIcon,
    required this.explanationTitle,
    required this.explanationBody,
    required this.supportingExplanationBody,
    required this.reviewSummary,
    required this.trialSummary,
    required this.manualCount,
  });

  factory _ZeroConfirmedRescueState.fromSnapshot(
    RuntimeDashboardSnapshot snapshot, {
    required RuntimeLocalMessageSourceStatus sourceStatus,
  }) {
    final trialCards = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
        .toList(growable: false);
    final reviewItems = snapshot.reviewQueue;
    final manualEntries = snapshot.manualSubscriptions;
    final hasReviewItems = reviewItems.isNotEmpty;
    final hasTrialCards = trialCards.isNotEmpty;

    final explanationTitle = hasReviewItems || hasTrialCards
        ? 'Why the confirmed list is still empty'
        : 'Why nothing is confirmed yet';
    final explanationBody = hasReviewItems
        ? 'Possible recurring items were kept in Review so SubWatch does not count them as paid too early.'
        : hasTrialCards
            ? 'This scan found trial or bundled access signals, and those stay separate from paid subscriptions.'
            : 'This scan did not surface recurring paid billing proof strong enough to confirm yet.';
    final supportingExplanationBody = hasReviewItems
        ? 'You can review each item yourself, add something manually, or wait for a later billing message to make the picture clearer.'
        : hasTrialCards
            ? 'Recharges, bundled access, and free benefits do not get counted as paid subscriptions. If you already know one you pay for directly, you can still add it manually.'
            : 'One-time payments, mandate setup, recharges, and bundled access are kept out of confirmed subscriptions on purpose. If you already know one you pay for, you can still add it manually.';

    return _ZeroConfirmedRescueState(
      sourceLabel: sourceStatus.title,
      sourceIcon: _sourceIconForTone(sourceStatus.tone),
      explanationTitle: explanationTitle,
      explanationBody: explanationBody,
      supportingExplanationBody: supportingExplanationBody,
      reviewSummary: _ZeroConfirmedFindingSummary(
        key: 'review',
        icon: Icons.rule_folder_outlined,
        title: 'Needs review',
        count: reviewItems.length,
        description: reviewItems.isEmpty
            ? 'No uncertain items were surfaced this time.'
            : _summarizeFindingTitles(
                reviewItems.map((item) => item.title),
                singularLabel: 'item waiting for a decision',
                pluralLabel: 'items waiting for a decision',
              ),
      ),
      trialSummary: _ZeroConfirmedFindingSummary(
        key: 'trialsBenefits',
        icon: Icons.workspace_premium_outlined,
        title: 'Trials & benefits',
        count: trialCards.length,
        description: trialCards.isEmpty
            ? 'No bundled or trial access stood out in this scan.'
            : _summarizeFindingTitles(
                trialCards.map((card) => card.title),
                singularLabel: 'separate access item found',
                pluralLabel: 'separate access items found',
              ),
      ),
      manualCount: manualEntries.length,
    );
  }

  final String sourceLabel;
  final IconData sourceIcon;
  final String explanationTitle;
  final String explanationBody;
  final String? supportingExplanationBody;
  final _ZeroConfirmedFindingSummary reviewSummary;
  final _ZeroConfirmedFindingSummary trialSummary;
  final int manualCount;

  List<_ZeroConfirmedFindingSummary> get visibleFindings =>
      <_ZeroConfirmedFindingSummary>[
        if (reviewSummary.count > 0) reviewSummary,
        if (trialSummary.count > 0) trialSummary,
      ];

  _ZeroConfirmedPrimaryActionKind get primaryActionKind {
    if (reviewSummary.count > 0) {
      return _ZeroConfirmedPrimaryActionKind.review;
    }
    if (trialSummary.count > 0 || manualCount > 0) {
      return _ZeroConfirmedPrimaryActionKind.subscriptions;
    }
    return _ZeroConfirmedPrimaryActionKind.manualAdd;
  }

  String get primaryActionLabel {
    switch (primaryActionKind) {
      case _ZeroConfirmedPrimaryActionKind.review:
        return reviewSummary.count == 1
            ? 'Review 1 item'
            : 'Review ${reviewSummary.count} items';
      case _ZeroConfirmedPrimaryActionKind.subscriptions:
        return trialSummary.count > 0
            ? 'See what was found'
            : 'Open subscriptions';
      case _ZeroConfirmedPrimaryActionKind.manualAdd:
        return 'Add manually';
    }
  }

  String? get actionHint {
    if (manualCount > 0) {
      return manualCount == 1
          ? '1 manual entry already stays separate in your subscriptions list.'
          : '$manualCount manual entries already stay separate in your subscriptions list.';
    }
    if (primaryActionKind == _ZeroConfirmedPrimaryActionKind.manualAdd) {
      return 'If you already know one you pay for, you can track it manually without changing this scan result.';
    }
    return null;
  }
}

enum _ZeroConfirmedPrimaryActionKind {
  review,
  subscriptions,
  manualAdd,
}

class _ZeroConfirmedFindingSummary {
  const _ZeroConfirmedFindingSummary({
    required this.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.description,
  });

  final String key;
  final IconData icon;
  final String title;
  final int count;
  final String description;
}

class _ZeroConfirmedFindingRow extends StatelessWidget {
  const _ZeroConfirmedFindingRow({
    required this.summary,
  });

  final _ZeroConfirmedFindingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey<String>('zero-confirmed-row-${summary.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: DashboardShellPalette.nestedPaper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DashboardShellPalette.outline.withValues(alpha: 0.9),
            ),
          ),
          child: Icon(
            summary.icon,
            size: 16,
            color: DashboardShellPalette.statusBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      summary.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    summary.count.toString(),
                    key:
                        ValueKey<String>('zero-confirmed-count-${summary.key}'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                summary.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      height: 1.22,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmsPermissionOnboardingSheet extends StatelessWidget {
  const _SmsPermissionOnboardingSheet({
    required this.onBrowseFirst,
    required this.onContinue,
  });

  final Future<void> Function() onBrowseFirst;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('sms-permission-onboarding-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: DashboardShellPalette.elevatedPaper,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: DashboardShellPalette.outline,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const SubWatchBrandMark(size: 32, showBase: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'SubWatch',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Find subscriptions in your messages',
                  key: const ValueKey<String>('sms-onboarding-title'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'SubWatch processes SMS to build a local subscription view. Raw SMS content is never saved.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey<String>(
                    'sms-permission-onboarding-continue-action',
                  ),
                  onPressed: () async {
                    await onContinue();
                  },
                  child: const Text('Get started'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  key: const ValueKey<String>(
                    'sms-permission-onboarding-browse-action',
                  ),
                  onPressed: () async {
                    await onBrowseFirst();
                  },
                  child: const Text('Browse sample'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmsPermissionRationaleSheet extends StatelessWidget {
  const _SmsPermissionRationaleSheet({
    required this.variant,
    required this.onContinue,
    required this.onSecondaryAction,
  });

  final RuntimeLocalMessageSourcePermissionRationaleVariant variant;
  final Future<void> Function() onContinue;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final content = _SmsPermissionRationaleContent.forVariant(variant);
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('sms-permission-rationale-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        content.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              content.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              content.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                FilledButton(
                  key: const ValueKey<String>(
                    'sms-permission-rationale-primary-action',
                  ),
                  onPressed: () {
                    onContinue();
                  },
                  child: Text(
                    content.primaryActionLabel,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  key: const ValueKey<String>(
                    'sms-permission-rationale-secondary-action',
                  ),
                  onPressed: onSecondaryAction,
                  child: Text(
                    content.secondaryActionLabel,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmsPermissionRationaleContent {
  const _SmsPermissionRationaleContent({
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
  });

  factory _SmsPermissionRationaleContent.forVariant(
    RuntimeLocalMessageSourcePermissionRationaleVariant variant,
  ) {
    switch (variant) {
      case RuntimeLocalMessageSourcePermissionRationaleVariant.firstRun:
        return const _SmsPermissionRationaleContent(
          title: 'Start with SMS permission',
          description:
              'SubWatch processes SMS to build a local subscription view. The raw SMS content is never saved. Only your summary is stored on this device.',
          primaryActionLabel: 'Start with SMS permission',
          secondaryActionLabel: 'Browse sample first',
        );

      case RuntimeLocalMessageSourcePermissionRationaleVariant.retry:
        return const _SmsPermissionRationaleContent(
          title: 'SMS access is off',
          description:
              'SubWatch needs SMS access to find your subscriptions. Raw SMS is never saved. Only your summary is stored on this device.',
          primaryActionLabel: 'Try again',
          secondaryActionLabel: 'Open Settings',
        );

    }
  }

  final String title;
  final String description;
  final String primaryActionLabel;
  final String secondaryActionLabel;
}

class _ReviewQueueSummaryCard extends StatelessWidget {
  const _ReviewQueueSummaryCard({
    required this.reviewCount,
  });

  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final countLabel = reviewCount == 1 ? '1 item' : '$reviewCount items';
    final isEmpty = reviewCount == 0;

    return DashboardPanel(
      key: const ValueKey<String>('review-queue-summary-card'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              DashboardBadge(
                label: isEmpty ? 'Clear for now' : '$countLabel to decide',
                icon: isEmpty
                    ? Icons.verified_outlined
                    : Icons.rule_folder_outlined,
                backgroundColor: isEmpty
                    ? DashboardShellPalette.successSoft
                    : DashboardShellPalette.cautionSoft,
                foregroundColor: isEmpty
                    ? DashboardShellPalette.success
                    : DashboardShellPalette.caution,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isEmpty
                ? 'Nothing to review right now.'
                : 'Ready for your decision',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupPanel extends DashboardSettingsGroupPanel {
  const _SettingsGroupPanel({
    super.key,
    required super.title,
    super.subtitle,
    required super.children,
  });
}

class _SettingsSubsection extends DashboardSettingsSubsection {
  const _SettingsSubsection({
    super.key,
    required super.title,
    required super.caption,
    required super.children,
  });
}

class _HelpAndPrivacySheet extends StatelessWidget {
  const _HelpAndPrivacySheet();

  @override
  Widget build(BuildContext context) {
    return _SettingsDetailSheet(
      sheetKey: const ValueKey<String>('help-privacy-sheet'),
      title: 'Help & privacy',
      subtitle: 'What stays local and how scans work.',
      children: const <Widget>[
        _TrustSheetSection(
          title: 'Scans',
          items: <String>[
            'SubWatch processes SMS to build a local subscription view.',
            'The raw SMS content is never saved or uploaded.',
            'Only your subscription summary is stored on this device.',
          ],

        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'Paid subscriptions',
          items: <String>[
            'Paid subscriptions need strong recurring billing proof.',
            'Single payments or setup messages are not enough.',
            'Weak signals stay in Review or Benefits.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'Review & benefits',
          items: <String>[
            'Review holds items that still need your decision.',
            'Trials, bundles, and free access stay outside paid subscriptions.',
            'Hide actions only change this phone view.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'What stays local',
          items: <String>[
            'Subscription summaries (service names, amounts, and dates) stay on this phone.',
            'Your decisions, manual entries, and reminders stay on this phone.',
            'A scan replaces the current local view on your phone.',
          ],
        ),

        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'What SubWatch does not do',
          items: <String>[
            'It does not upload your SMS inbox.',
            'It does not run passive background monitoring.',
            'It does not count every payment as a subscription.',
          ],
        ),
      ],
    );
  }
}

class _AboutSubWatchSheet extends StatelessWidget {
  const _AboutSubWatchSheet();

  @override
  Widget build(BuildContext context) {
    return _SettingsDetailSheet(
      sheetKey: const ValueKey<String>('about-subwatch-sheet'),
      title: 'About SubWatch',
      subtitle: 'What SubWatch helps you track.',
      children: const <Widget>[
        _TrustSheetSection(
          title: 'What SubWatch is',
          items: <String>[
            'SubWatch helps you spot subscriptions from your messages.',
            'It separates paid subscriptions from uncertain items.',
            'It keeps bundled benefits and trials separate.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'What SubWatch is not',
          items: <String>[
            'It is not a payments inbox or budget tracker.',
            'It does not rely on cloud accounts or upload data.',
            'It does not silently watch messages in the background.',
          ],
        ),
      ],
    );
  }
}

class _SettingsDetailSheet extends DashboardDetailSheet {
  const _SettingsDetailSheet({
    required super.sheetKey,
    required super.title,
    required super.subtitle,
    required super.children,
  });
}

class _SettingsNavRow extends DashboardSettingsNavRow {
  const _SettingsNavRow({
    required super.tileKey,
    required super.icon,
    required super.title,
    required super.subtitle,
    super.onTap,
    super.trailing,
  });
}

class _SettingsRecoveryRow extends DashboardSettingsRecoveryRow {
  const _SettingsRecoveryRow({
    super.key,
    required super.title,
    required super.subtitle,
    required super.statusLabel,
    required super.isBusy,
    required super.actionKey,
    required super.onUndo,
  });
}

class _SettingsGroupDivider extends DashboardSettingsGroupDivider {
  const _SettingsGroupDivider();
}

class _TrustSheetSection extends DashboardTrustSection {
  const _TrustSheetSection({
    required super.title,
    required super.items,
  });
}

class _DashboardSection extends DashboardSectionBlock {
  const _DashboardSection({
    super.key,
    required super.title,
    required super.children,
    super.countLabel,
    super.caption,
  });
}

class _EmptySectionText extends DashboardEmptySection {
  const _EmptySectionText({
    required super.title,
    required super.message,
    required super.icon,
  });
}

class _ServiceViewControlsPanel extends StatelessWidget {
  const _ServiceViewControlsPanel({
    required this.searchController,
    required this.controls,
    required this.availableFilterModes,
    required this.onAddManual,
    required this.onSortChanged,
    required this.onFilterChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final DashboardServiceViewControls controls;
  final List<DashboardServiceFilterMode> availableFilterModes;
  final Future<void> Function() onAddManual;
  final ValueChanged<DashboardServiceSortMode> onSortChanged;
  final ValueChanged<DashboardServiceFilterMode> onFilterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final actionButtons = <Widget>[
      _ServiceViewMenuButton<DashboardServiceSortMode>(
        menuKey: const ValueKey<String>('service-sort-menu'),
        tooltip: 'Sort subscriptions',
        semanticLabel: 'Sort subscriptions',
        icon: Icons.swap_vert_rounded,
        active: controls.sortMode != DashboardServiceSortMode.currentOrder,
        itemBuilder: (context) => DashboardServiceSortMode.values
            .map(
              (mode) => CheckedPopupMenuItem<DashboardServiceSortMode>(
                value: mode,
                checked: controls.sortMode == mode,
                child: Text(_sortLabel(mode)),
              ),
            )
            .toList(growable: false),
        onSelected: onSortChanged,
      ),
      _ServiceViewMenuButton<DashboardServiceFilterMode>(
        menuKey: const ValueKey<String>('service-filter-menu'),
        tooltip: 'Filter subscriptions',
        semanticLabel: 'Filter subscriptions',
        icon: Icons.tune_rounded,
        active: controls.isFilterActive,
        itemBuilder: (context) => availableFilterModes
            .map(
              (mode) => CheckedPopupMenuItem<DashboardServiceFilterMode>(
                value: mode,
                checked: controls.filterMode == mode,
                child: Text(_filterLabel(mode)),
              ),
            )
            .toList(growable: false),
        onSelected: onFilterChanged,
      ),
      FloatingActionButton.small(
        key: const ValueKey<String>('open-manual-subscription-form'),
        heroTag: 'open-manual-subscription-form',
        tooltip: 'Add manually',
        onPressed: onAddManual,
        backgroundColor: DashboardShellPalette.accent,
        foregroundColor: DashboardShellPalette.canvas,
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(Icons.add_rounded),
      ),
      if (controls.hasActiveControls)
        _ServiceViewIconButton(
          key: const ValueKey<String>('reset-service-view-controls'),
          tooltip: 'Reset view',
          semanticLabel: 'Reset subscriptions view',
          icon: Icons.refresh_rounded,
          onPressed: onClear,
        ),
    ];

    return Container(
      key: const ValueKey<String>('service-view-controls-panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: DashboardShellPalette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardShellPalette.outline),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedActions =
              constraints.maxWidth < 440 || textScale > 1.12;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (useStackedActions) ...<Widget>[
                TextField(
                  key: const ValueKey<String>('service-search-input'),
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search subscriptions',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: controls.isSearchActive
                        ? IconButton(
                            key: const ValueKey<String>('clear-service-search'),
                            tooltip: 'Clear search',
                            onPressed: () => searchController.clear(),
                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actionButtons,
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        key: const ValueKey<String>('service-search-input'),
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search subscriptions',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: controls.isSearchActive
                              ? IconButton(
                                  key: const ValueKey<String>(
                                    'clear-service-search',
                                  ),
                                  tooltip: 'Clear search',
                                  onPressed: () => searchController.clear(),
                                  icon: const Icon(Icons.close_rounded),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...actionButtons.expand(
                      (button) => <Widget>[
                        button,
                        const SizedBox(width: 8),
                      ],
                    ),
                  ]..removeLast(),
                ),
            ],
          );
        },
      ),
    );
  }

  String _sortLabel(DashboardServiceSortMode mode) {
    switch (mode) {
      case DashboardServiceSortMode.currentOrder:
        return 'Default';
      case DashboardServiceSortMode.nameAscending:
        return 'Name A-Z';
      case DashboardServiceSortMode.nameDescending:
        return 'Name Z-A';
    }
  }

  String _filterLabel(DashboardServiceFilterMode mode) {
    switch (mode) {
      case DashboardServiceFilterMode.allVisible:
        return 'All';
      case DashboardServiceFilterMode.confirmedOnly:
        return 'Subscriptions';
      case DashboardServiceFilterMode.observedOnly:
        return 'Needs review';
      case DashboardServiceFilterMode.separateAccessOnly:
        return 'Trials & benefits';
    }
  }
}

class _ServiceViewMenuButton<T> extends StatelessWidget {
  const _ServiceViewMenuButton({
    required this.menuKey,
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.active,
    required this.itemBuilder,
    required this.onSelected,
  });

  final Key menuKey;
  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final bool active;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      key: menuKey,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      color: DashboardShellPalette.elevatedPaper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active
              ? DashboardShellPalette.statusBlue.withValues(alpha: 0.32)
              : DashboardShellPalette.outlineStrong,
        ),
      ),
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      child: _ServiceViewControlSurface(
        semanticLabel: semanticLabel,
        icon: icon,
        active: active,
      ),
    );
  }
}

class _ServiceViewIconButton extends StatelessWidget {
  const _ServiceViewIconButton({
    super.key,
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onTap: onPressed,
          child: _ServiceViewControlSurface(
            semanticLabel: semanticLabel,
            icon: icon,
            active: active,
          ),
        ),
      ),
    );
  }
}

class _ServiceViewControlSurface extends StatelessWidget {
  const _ServiceViewControlSurface({
    required this.semanticLabel,
    required this.icon,
    this.active = false,
  });

  final String semanticLabel;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = active
        ? DashboardShellPalette.statusBlue
        : DashboardShellPalette.mutedInk;
    final backgroundColor = active
        ? DashboardShellPalette.statusBlueSoft
        : DashboardShellPalette.nestedPaper;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? DashboardShellPalette.statusBlue.withValues(alpha: 0.26)
                : DashboardShellPalette.outlineStrong,
          ),
        ),
        child: Icon(icon, size: 20, color: foregroundColor),
      ),
    );
  }
}

class _CollapsedSubscriptionSection extends StatefulWidget {
  const _CollapsedSubscriptionSection({
    required this.sectionKey,
    required this.label,
    required this.icon,
    required this.children,
  });

  final String sectionKey;
  final String label;
  final IconData icon;
  final List<Widget> children;

  @override
  State<_CollapsedSubscriptionSection> createState() =>
      _CollapsedSubscriptionSectionState();
}

class _CollapsedSubscriptionSectionState
    extends State<_CollapsedSubscriptionSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      key: ValueKey<String>('toggle-section-${widget.sectionKey}'),
      backgroundColor: DashboardShellPalette.nestedPaper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 18,
                  color: DashboardShellPalette.benefitGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _isExpanded
                      ? DashboardShellPalette.benefitGold
                      : DashboardShellPalette.mutedInk,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kept separate from paid subscriptions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                  ),
            ),
            if (_isExpanded) ...<Widget>[
              const SizedBox(height: 12),
              ...widget.children,
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceViewEmptyState extends StatelessWidget {
  const _ServiceViewEmptyState({
    required this.onClear,
  });

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('service-view-empty-state'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EmptySectionText(
          title: 'Nothing matches this view',
          message:
              'Try another search or reset the filters. If something is still missing, you can add it manually.',
          icon: Icons.search_off_rounded,
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          key: const ValueKey<String>('reset-service-view-controls-empty'),
          onPressed: onClear,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}

class _TotalsExplanationSheet extends StatelessWidget {
  const _TotalsExplanationSheet({
    required this.presentation,
  });

  final DashboardTotalsSummaryPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('totals-explanation-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        presentation.explainerTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.summaryCopy,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              presentation.explainerTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              presentation.summaryCopy,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                ...presentation.explainerBullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: DashboardShellPalette.statusBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bullet,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: DashboardShellPalette.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenewalReminderControlsSheet extends StatelessWidget {
  const _RenewalReminderControlsSheet({
    required this.item,
    required this.isBusy,
    required this.onSelectPreset,
    required this.onDisable,
  });

  final DashboardRenewalReminderItemPresentation item;
  final bool isBusy;
  final Future<void> Function(RenewalReminderLeadTimePreset preset)
      onSelectPreset;
  final Future<void> Function()? onDisable;

  @override
  Widget build(BuildContext context) {
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
            'renewal-reminder-controls-sheet-${item.renewal.serviceKey}',
          ),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        'Local reminder',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reminders stay on this phone and appear only for clear dates.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Local reminder',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reminders stay on this phone and appear only for clear dates.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outlineStrong,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.renewal.serviceTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Renews on ${item.renewal.renewalDateLabel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                      if (item.renewal.amountLabel != null) ...<Widget>[
                        const SizedBox(height: 8),
                        DashboardBadge(
                          label: item.renewal.amountLabel!,
                          backgroundColor: DashboardShellPalette.paper,
                          foregroundColor: DashboardShellPalette.statusBlue,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Remind me',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (item.availablePresets.isEmpty)
                  Text(
                    'No safe reminder time is left for this cycle.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                        ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: item.availablePresets
                        .map(
                          (preset) => FilledButton(
                            key: ValueKey<String>(
                              'enable-reminder-${item.renewal.serviceKey}-${preset.name}',
                            ),
                            onPressed:
                                isBusy ? null : () => onSelectPreset(preset),
                            child: Text(
                              item.selectedPreset == preset
                                  ? '${preset.label} selected'
                                  : preset.label,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                if (onDisable != null) ...<Widget>[
                  const SizedBox(height: 12),
                  TextButton(
                    key: ValueKey<String>(
                      'disable-reminder-${item.renewal.serviceKey}',
                    ),
                    onPressed: isBusy ? null : onDisable,
                    child: const Text('Remove reminder'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualSubscriptionRow extends StatelessWidget {
  const _ManualSubscriptionRow({
    super.key,
    required this.entry,
    required this.isBusy,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenReminderControls,
  });

  final ManualSubscriptionEntry entry;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenReminderControls;

  @override
  Widget build(BuildContext context) {
    final amountLabel =
        _formatManualSubscriptionAmount(entry.amountInMinorUnits) ??
            'Amount not added';
    final renewalLabel = entry.hasNextRenewalDate
        ? _formatManualDate(entry.nextRenewalDate!)
        : 'No renewal date';
    final identity = _identityStyle(
      entry.serviceName,
      accentColor: DashboardShellPalette.statusBlue,
    );
    final summary = _manualSubscriptionRowSemantics(entry);
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;
    final expandedSubtitle = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.15;

    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Semantics(
              key: ValueKey<String>('manual-row-semantics-${entry.id}'),
              button: true,
              label: summary,
              hint: 'Opens manual entry details',
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  splashColor:
                      DashboardShellPalette.statusBlue.withValues(alpha: 0.08),
                  highlightColor:
                      DashboardShellPalette.statusBlue.withValues(alpha: 0.04),
                  hoverColor:
                      DashboardShellPalette.statusBlue.withValues(alpha: 0.03),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 0, 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DashboardServiceAvatar(
                          monogram: identity.monogram,
                          foregroundColor: identity.foreground,
                          backgroundColor: identity.background,
                          borderColor: identity.border,
                          sealColor: DashboardShellPalette.statusBlue,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (stackedHeader)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      entry.serviceName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    const DashboardBadge(
                                      label: 'Added by you',
                                      backgroundColor:
                                          DashboardShellPalette.registerPaper,
                                      foregroundColor:
                                          DashboardShellPalette.statusBlue,
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        entry.serviceName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const DashboardBadge(
                                      label: 'Added by you',
                                      backgroundColor:
                                          DashboardShellPalette.registerPaper,
                                      foregroundColor:
                                          DashboardShellPalette.statusBlue,
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Text(
                                _manualSubscriptionSubtitle(entry),
                                maxLines: expandedSubtitle ? null : 2,
                                overflow: expandedSubtitle
                                    ? null
                                    : TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              _SubscriptionMetaPanel(
                                amountValueKey: ValueKey<String>(
                                  'manual-meta-amount-${entry.id}',
                                ),
                                amountLabel: amountLabel,
                                renewalValueKey: ValueKey<String>(
                                  'manual-meta-renewal-${entry.id}',
                                ),
                                renewalLabel: renewalLabel,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 11, 8, 11),
            child: SizedBox.square(
              dimension: 48,
              child: PopupMenuButton<String>(
                key:
                    ValueKey<String>('manual-subscription-actions-${entry.id}'),
                enabled: !isBusy,
                tooltip: 'More actions for ${entry.serviceName}',
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                    case 'reminder':
                      onOpenReminderControls?.call();
                      break;
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit details'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Remove from list'),
                  ),
                  if (onOpenReminderControls != null)
                    const PopupMenuItem<String>(
                      value: 'reminder',
                      child: Text('Set local reminder'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualSubscriptionDetailsSheet extends StatelessWidget {
  const _ManualSubscriptionDetailsSheet({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenReminderControls,
  });

  final ManualSubscriptionEntry entry;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final VoidCallback? onOpenReminderControls;

  @override
  Widget build(BuildContext context) {
    final identity = _identityStyle(
      entry.serviceName,
      accentColor: DashboardShellPalette.statusBlue,
    );

    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>('manual-subscription-details-${entry.id}'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          DashboardServiceAvatar(
                            monogram: identity.monogram,
                            foregroundColor: identity.foreground,
                            backgroundColor: identity.background,
                            borderColor: identity.border,
                            sealColor: DashboardShellPalette.statusBlue,
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  entry.serviceName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Saved on this phone and kept separate from scans.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color:
                                              DashboardShellPalette.mutedInk),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DashboardServiceAvatar(
                        monogram: identity.monogram,
                        foregroundColor: identity.foreground,
                        backgroundColor: identity.background,
                        borderColor: identity.border,
                        sealColor: DashboardShellPalette.statusBlue,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entry.serviceName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saved on this phone and kept separate from scans.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    const DashboardBadge(
                      label: 'Added by you',
                      backgroundColor: DashboardShellPalette.registerPaper,
                      foregroundColor: DashboardShellPalette.statusBlue,
                    ),
                    DashboardBadge(
                      label: entry.billingCycle ==
                              ManualSubscriptionBillingCycle.monthly
                          ? 'Monthly'
                          : 'Yearly',
                      backgroundColor: DashboardShellPalette.paper,
                      foregroundColor: DashboardShellPalette.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!entry.hasAmount || !entry.hasNextRenewalDate) ...<Widget>[
                  DashboardPanel(
                    backgroundColor: DashboardShellPalette.elevatedPaper,
                    borderColor: DashboardShellPalette.outline,
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Make this entry more useful',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _manualEntryImprovementCopy(entry),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                    height: 1.28,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _ManualSubscriptionDetailBlock(
                  title: 'Billing',
                  value: _manualSubscriptionBillingSummary(entry),
                ),
                if (entry.hasPlanLabel) ...<Widget>[
                  const SizedBox(height: 10),
                  _ManualSubscriptionDetailBlock(
                    title: 'Plan label',
                    value: entry.planLabel!,
                  ),
                ],
                if (entry.hasNextRenewalDate) ...<Widget>[
                  const SizedBox(height: 10),
                  _ManualSubscriptionDetailBlock(
                    title: 'Next renewal',
                    value: _formatManualDate(entry.nextRenewalDate!),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _ContextualActionSemantics(
                      label: 'Edit manual entry for ${entry.serviceName}',
                      child: FilledButton(
                        key: ValueKey<String>(
                            'edit-manual-subscription-${entry.id}'),
                        onPressed: onEdit,
                        child: const Text('Edit details'),
                      ),
                    ),
                    _ContextualActionSemantics(
                      label: 'Remove manual entry for ${entry.serviceName}',
                      child: TextButton(
                        key: ValueKey<String>(
                            'delete-manual-subscription-${entry.id}'),
                        onPressed: onDelete,
                        child: const Text('Remove from list'),
                      ),
                    ),
                    if (onOpenReminderControls != null)
                      _ContextualActionSemantics(
                        label: 'Set a local reminder for ${entry.serviceName}',
                        child: TextButton.icon(
                          key: ValueKey<String>(
                              'open-reminder-manual-subscription-${entry.id}'),
                          onPressed: onOpenReminderControls,
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                          ),
                          label: const Text('Set local reminder'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualSubscriptionDetailBlock extends StatelessWidget {
  const _ManualSubscriptionDetailBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      backgroundColor: DashboardShellPalette.elevatedPaper,
      borderColor: DashboardShellPalette.outline,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardShellPalette.ink,
                ),
          ),
        ],
      ),
    );
  }
}

class _ManualAddFlowSheet extends StatefulWidget {
  const _ManualAddFlowSheet({required this.onSubmit});

  final Future<bool> Function(_ManualSubscriptionFormValue value) onSubmit;

  @override
  State<_ManualAddFlowSheet> createState() => _ManualAddFlowSheetState();
}

class _ManualAddFlowSheetState extends State<_ManualAddFlowSheet> {
  PopularServiceEntry? _pickedEntry;
  bool _showEditor = false;

  void _onPickService(PopularServiceEntry entry) {
    setState(() {
      _pickedEntry = entry;
      _showEditor = true;
    });
  }

  void _onCustomEntry() {
    setState(() {
      _pickedEntry = null;
      _showEditor = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showEditor) {
      return _ManualSubscriptionEditorSheet(
        initialServiceName: _pickedEntry?.name,
        initialPlanLabel: _pickedEntry?.planLabel,
        initialAmountInMinorUnits: _pickedEntry?.suggestedAmountInMinorUnits,
        initialBillingCycle: _pickedEntry?.billingCycle,
        onSubmit: widget.onSubmit,
      );
    }

    return _PopularServicePickerInline(
      onPickService: _onPickService,
      onCustomEntry: _onCustomEntry,
    );
  }
}

class _PopularServicePickerInline extends StatefulWidget {
  const _PopularServicePickerInline({
    required this.onPickService,
    required this.onCustomEntry,
  });

  final void Function(PopularServiceEntry entry) onPickService;
  final VoidCallback onCustomEntry;

  @override
  State<_PopularServicePickerInline> createState() =>
      _PopularServicePickerInlineState();
}

class _PopularServicePickerInlineState
    extends State<_PopularServicePickerInline> {
  final TextEditingController _searchController = TextEditingController();
  List<PopularServiceEntry> _filteredEntries = PopularServiceCatalog.entries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredEntries = PopularServiceCatalog.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('popular-service-picker'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        'Add a subscription you already know',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start with a popular service or add your own. Manual entries stay marked as added by you.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Add a subscription you already know',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start with a popular service or add your own. Manual entries stay marked as added by you.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <Widget>[
                    DashboardBadge(
                      label: 'Added by you',
                      icon: Icons.edit_note_rounded,
                      backgroundColor: DashboardShellPalette.registerPaper,
                      foregroundColor: DashboardShellPalette.statusBlue,
                    ),
                    DashboardBadge(
                      label: 'Does not change scan results',
                      icon: Icons.verified_outlined,
                      backgroundColor: DashboardShellPalette.elevatedPaper,
                      foregroundColor: DashboardShellPalette.mutedInk,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('popular-service-search'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search popular services',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: DashboardShellPalette.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: DashboardShellPalette.outline,
                      ),
                    ),
                    filled: true,
                    fillColor: DashboardShellPalette.elevatedPaper,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final entry in _filteredEntries)
                      _PopularServiceChip(
                        entry: entry,
                        onTap: () {
                          widget.onPickService(entry);
                        },
                      ),
                    _CustomEntryChip(
                      onTap: widget.onCustomEntry,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularServicePickerSheet extends StatefulWidget {
  const _PopularServicePickerSheet();

  @override
  State<_PopularServicePickerSheet> createState() =>
      _PopularServicePickerSheetState();
}

class _PopularServicePickerSheetState
    extends State<_PopularServicePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<PopularServiceEntry> _filteredEntries = PopularServiceCatalog.entries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredEntries = PopularServiceCatalog.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('popular-service-picker'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        'Add a subscription you already know',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start with a popular service or add your own. Manual entries stay marked as added by you.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Add a subscription you already know',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start with a popular service or add your own. Manual entries stay marked as added by you.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <Widget>[
                    DashboardBadge(
                      label: 'Added by you',
                      icon: Icons.edit_note_rounded,
                      backgroundColor: DashboardShellPalette.registerPaper,
                      foregroundColor: DashboardShellPalette.statusBlue,
                    ),
                    DashboardBadge(
                      label: 'Does not change scan results',
                      icon: Icons.verified_outlined,
                      backgroundColor: DashboardShellPalette.elevatedPaper,
                      foregroundColor: DashboardShellPalette.mutedInk,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('popular-service-search'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search popular services',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: DashboardShellPalette.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: DashboardShellPalette.outline,
                      ),
                    ),
                    filled: true,
                    fillColor: DashboardShellPalette.elevatedPaper,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final entry in _filteredEntries)
                      _PopularServiceChip(
                        entry: entry,
                        onTap: () {
                          Navigator.of(context).pop(entry);
                        },
                      ),
                    _CustomEntryChip(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularServiceChip extends StatelessWidget {
  const _PopularServiceChip({
    required this.entry,
    required this.onTap,
  });

  final PopularServiceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brandEntry = ServiceIconRegistry.lookup(entry.serviceKey);
    final identity = _identityStyle(
      entry.name,
      accentColor: brandEntry?.brandColor ?? DashboardShellPalette.statusBlue,
    );

    final amountLabel = entry.suggestedAmountInMinorUnits == null
        ? null
        : _formatChipAmount(entry.suggestedAmountInMinorUnits!);
    final cycleLabel =
        entry.billingCycle == ManualSubscriptionBillingCycle.yearly
            ? '/yr'
            : '/mo';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor:
            (brandEntry?.brandColor ?? DashboardShellPalette.statusBlue)
            .withValues(alpha: 0.08),
        highlightColor:
            (brandEntry?.brandColor ?? DashboardShellPalette.statusBlue)
            .withValues(alpha: 0.04),
        hoverColor:
            (brandEntry?.brandColor ?? DashboardShellPalette.statusBlue)
            .withValues(alpha: 0.03),
        child: Container(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: DashboardShellPalette.elevatedPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DashboardShellPalette.outline.withValues(alpha: 0.78),
            ),
          ),
          child: Row(
            children: <Widget>[
              DashboardServiceAvatar(
                monogram: identity.monogram,
                foregroundColor: identity.foreground,
                backgroundColor: identity.background,
                borderColor: identity.border,
                serviceKey: entry.serviceKey,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (amountLabel != null)
                      Text(
                        '$amountLabel$cycleLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomEntryChip extends StatelessWidget {
  const _CustomEntryChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: DashboardShellPalette.statusBlue.withValues(alpha: 0.08),
        highlightColor:
            DashboardShellPalette.statusBlue.withValues(alpha: 0.04),
        hoverColor: DashboardShellPalette.statusBlue.withValues(alpha: 0.03),
        child: Container(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: DashboardShellPalette.elevatedPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DashboardShellPalette.statusBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DashboardShellPalette.statusBlueSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        DashboardShellPalette.statusBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: DashboardShellPalette.statusBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Something else',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DashboardShellPalette.statusBlue,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatChipAmount(int amountInMinorUnits) {
  final whole = amountInMinorUnits ~/ 100;
  return '\u20B9$whole';
}

class _ManualSubscriptionEditorSheet extends StatefulWidget {
  const _ManualSubscriptionEditorSheet({
    required this.onSubmit,
    this.existingEntry,
    this.onDelete,
    this.initialServiceName,
    this.initialPlanLabel,
    this.initialAmountInMinorUnits,
    this.initialBillingCycle,
  });

  final ManualSubscriptionEntry? existingEntry;
  final Future<bool> Function(_ManualSubscriptionFormValue value) onSubmit;
  final Future<bool> Function()? onDelete;
  final String? initialServiceName;
  final String? initialPlanLabel;
  final int? initialAmountInMinorUnits;
  final ManualSubscriptionBillingCycle? initialBillingCycle;

  @override
  State<_ManualSubscriptionEditorSheet> createState() =>
      _ManualSubscriptionEditorSheetState();
}

class _ManualSubscriptionEditorSheetState
    extends State<_ManualSubscriptionEditorSheet> {
  late final TextEditingController _serviceNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _planLabelController;
  late ManualSubscriptionBillingCycle _billingCycle;
  DateTime? _nextRenewalDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController(
      text:
          widget.existingEntry?.serviceName ?? widget.initialServiceName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingEntry?.amountInMinorUnits == null
          ? (widget.initialAmountInMinorUnits == null
              ? ''
              : _formatManualAmountInput(widget.initialAmountInMinorUnits!))
          : _formatManualAmountInput(widget.existingEntry!.amountInMinorUnits!),
    );
    _planLabelController = TextEditingController(
      text: widget.existingEntry?.planLabel ?? widget.initialPlanLabel ?? '',
    );
    _billingCycle = widget.existingEntry?.billingCycle ??
        widget.initialBillingCycle ??
        ManualSubscriptionBillingCycle.monthly;
    _nextRenewalDate = widget.existingEntry?.nextRenewalDate;
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _amountController.dispose();
    _planLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;
    final canSave = !_isSaving && _serviceNameController.text.trim().isNotEmpty;
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
            isEditing
                ? 'manual-subscription-editor-${widget.existingEntry!.id}'
                : 'manual-subscription-editor-new',
          ),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Edit manual entry'
                            : 'Add a manual subscription',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add one yourself when you want to track it.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              isEditing
                                  ? 'Edit manual entry'
                                  : 'Add a manual subscription',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add one yourself when you want to track it.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                DashboardPanel(
                  key: const ValueKey<String>('manual-subscription-guidance'),
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outline,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'How this helps',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add an amount for estimates. Add a date for renewals.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                              height: 1.28,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('manual-service-name-input'),
                  controller: _serviceNameController,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Service name',
                    hintText: 'Netflix, Adobe, Gym membership',
                    helperText: 'Use the name you will recognise.',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey<String>('manual-amount-input'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (optional)',
                    hintText: '499',
                    helperText: 'Adds this to your estimate.',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ManualSubscriptionBillingCycle>(
                  key: const ValueKey<String>('manual-billing-cycle-input'),
                  initialValue: _billingCycle,
                  decoration: const InputDecoration(
                    labelText: 'Billing cycle',
                    helperText: 'Matches the amount you enter.',
                  ),
                  items: const <DropdownMenuItem<
                      ManualSubscriptionBillingCycle>>[
                    DropdownMenuItem<ManualSubscriptionBillingCycle>(
                      value: ManualSubscriptionBillingCycle.monthly,
                      child: Text('Monthly'),
                    ),
                    DropdownMenuItem<ManualSubscriptionBillingCycle>(
                      value: ManualSubscriptionBillingCycle.yearly,
                      child: Text('Yearly'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _billingCycle = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey<String>('manual-plan-label-input'),
                  controller: _planLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Plan label (optional)',
                    hintText: 'Family, Premium, Annual plan',
                    helperText: 'Helps you spot it later.',
                  ),
                ),
                const SizedBox(height: 10),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outline,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Next renewal (optional)',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _nextRenewalDate == null
                            ? 'Not set'
                            : _formatManualDate(_nextRenewalDate!),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a date to show this in renewals.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton(
                            key: const ValueKey<String>(
                                'manual-pick-renewal-date'),
                            onPressed: _pickNextRenewalDate,
                            child: Text(
                              _nextRenewalDate == null
                                  ? 'Add date'
                                  : 'Change date',
                            ),
                          ),
                          if (_nextRenewalDate != null)
                            TextButton(
                              key: const ValueKey<String>(
                                  'manual-clear-renewal-date'),
                              onPressed: () {
                                setState(() {
                                  _nextRenewalDate = null;
                                });
                              },
                              child: const Text('Clear date'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton(
                      key: const ValueKey<String>('save-manual-subscription'),
                      onPressed: canSave ? _submit : null,
                      child:
                          Text(isEditing ? 'Save changes' : 'Add to your list'),
                    ),
                    if (widget.onDelete != null)
                      TextButton(
                        key: const ValueKey<String>(
                            'delete-manual-subscription'),
                        onPressed: _isSaving ? null : _delete,
                        child: const Text('Delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
    });

    final saved = await widget.onSubmit(
      _ManualSubscriptionFormValue(
        serviceName: _serviceNameController.text,
        amountInput: _amountController.text,
        billingCycle: _billingCycle,
        nextRenewalDate: _nextRenewalDate,
        planLabel: _planLabelController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (saved) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    setState(() {
      _isSaving = true;
    });

    final deleted = await widget.onDelete!();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (deleted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickNextRenewalDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextRenewalDate ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _nextRenewalDate = picked;
    });
  }
}

class _ManualSubscriptionFormValue {
  const _ManualSubscriptionFormValue({
    required this.serviceName,
    required this.amountInput,
    required this.billingCycle,
    required this.nextRenewalDate,
    required this.planLabel,
  });

  final String serviceName;
  final String amountInput;
  final ManualSubscriptionBillingCycle billingCycle;
  final DateTime? nextRenewalDate;
  final String planLabel;
}

class _LocalServiceControlsSheet extends StatefulWidget {
  const _LocalServiceControlsSheet({
    required this.card,
    required this.servicePresentationState,
    required this.isBusy,
    required this.onSaveLabel,
    required this.onResetLabel,
    required this.onTogglePin,
  });

  final DashboardCard card;
  final LocalServicePresentationState servicePresentationState;
  final bool isBusy;
  final Future<void> Function(String label) onSaveLabel;
  final Future<void> Function()? onResetLabel;
  final Future<void> Function() onTogglePin;

  @override
  State<_LocalServiceControlsSheet> createState() =>
      _LocalServiceControlsSheetState();
}

class _LocalServiceControlsSheetState
    extends State<_LocalServiceControlsSheet> {
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.servicePresentationState.localLabel ?? '',
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedLabel = _labelController.text.trim();
    final canSaveLabel = !widget.isBusy &&
        normalizedLabel.isNotEmpty &&
        normalizedLabel != widget.servicePresentationState.displayTitle;

    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
            'local-service-controls-sheet-${widget.card.serviceKey.value}',
          ),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        'On this phone',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'These changes only affect this phone view.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'On this phone',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'These changes only affect this phone view.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outlineStrong,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Detected name',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.servicePresentationState.originalTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Name in app',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: ValueKey<String>(
                          'local-label-input-${widget.card.serviceKey.value}',
                        ),
                        controller: _labelController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rename for your list',
                          filled: true,
                          fillColor: DashboardShellPalette.nestedPaper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: DashboardShellPalette.outlineStrong,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: DashboardShellPalette.outlineStrong,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: DashboardShellPalette.statusBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: <Widget>[
                          FilledButton(
                            key: ValueKey<String>(
                              'save-local-label-${widget.card.serviceKey.value}',
                            ),
                            onPressed: canSaveLabel
                                ? () => widget.onSaveLabel(normalizedLabel)
                                : null,
                            child: const Text('Save name'),
                          ),
                          if (widget.onResetLabel != null)
                            TextButton(
                              key: ValueKey<String>(
                                'reset-local-label-${widget.card.serviceKey.value}',
                              ),
                              onPressed:
                                  widget.isBusy ? null : widget.onResetLabel,
                              child: const Text('Clear name'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'List position',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.servicePresentationState.isPinned
                            ? 'Pinned items stay near the top.'
                            : 'Pin this item near the top.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        key: ValueKey<String>(
                          widget.servicePresentationState.isPinned
                              ? 'unpin-service-${widget.card.serviceKey.value}'
                              : 'pin-service-${widget.card.serviceKey.value}',
                        ),
                        onPressed: widget.isBusy ? null : widget.onTogglePin,
                        child: Text(
                          widget.servicePresentationState.isPinned
                              ? 'Unpin'
                              : 'Pin near top',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({
    required this.title,
    required this.subtitle,
    required this.stampLabel,
    required this.accentColor,
    required this.stampBackgroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.identity,
    this.serviceKey,
    this.secondaryStampLabel,
    this.secondaryStampBackgroundColor,
    this.secondaryStampForegroundColor,
    this.evidenceLabel,
    this.evidenceText,
    this.footer,
    this.headerTrailing,
  });

  final String title;
  final String subtitle;
  final String stampLabel;
  final Color accentColor;
  final Color stampBackgroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final _PassportIdentityStyle identity;
  final String? serviceKey;
  final String? secondaryStampLabel;
  final Color? secondaryStampBackgroundColor;
  final Color? secondaryStampForegroundColor;
  final String? evidenceLabel;
  final String? evidenceText;
  final Widget? footer;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 14.0;
    const topPadding = 14.0;
    const bottomPadding = 12.0;
    const accentBarWidth = 5.0;
    const accentBarHeight = 52.0;
    const avatarSize = 44.0;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        );

    return DashboardPanel(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.alphaBlend(
            Colors.white.withValues(alpha: 0.02),
            backgroundColor,
          ),
          Color.alphaBlend(
            Colors.black.withValues(alpha: 0.16),
            backgroundColor,
          ),
        ],
      ),
      borderColor: borderColor,
      radius: 22,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: accentBarWidth,
                height: accentBarHeight,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              DashboardServiceAvatar(
                key: ValueKey<String>('passport-avatar-$title'),
                monogram: identity.monogram,
                foregroundColor: identity.foreground,
                backgroundColor: identity.background,
                borderColor: identity.border,
                serviceKey: serviceKey,
                sealColor: accentColor,
                size: avatarSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                          ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        DashboardBadge(
                          label: stampLabel,
                          backgroundColor: stampBackgroundColor,
                          foregroundColor: accentColor,
                        ),
                        if (secondaryStampLabel != null)
                          DashboardBadge(
                            label: secondaryStampLabel!,
                            backgroundColor: secondaryStampBackgroundColor ??
                                DashboardShellPalette.paper,
                            foregroundColor:
                                secondaryStampForegroundColor ?? accentColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (headerTrailing != null) ...<Widget>[
                const SizedBox(width: 8),
                headerTrailing!,
              ],
            ],
          ),
          if (evidenceLabel != null && evidenceText != null) ...<Widget>[
            const SizedBox(height: 10),
            DashboardPanel(
              backgroundColor: DashboardShellPalette.nestedPaper,
              borderColor: accentColor.withValues(alpha: 0.2),
              radius: 16,
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    evidenceLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evidenceText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                        ),
                  ),
                ],
              ),
            ),
          ],
          if (footer != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: borderColor.withValues(alpha: 0.75),
                  ),
                ),
              ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

enum _SubscriptionCardMenuAction {
  explain,
  organize,
  hide,
  ignore,
}

enum _ReviewCardMenuAction {
  explain,
  ignore,
}

class _SubscriptionCardOverflowButton extends StatelessWidget {
  const _SubscriptionCardOverflowButton({
    required this.bucket,
    required this.card,
    required this.explanation,
    required this.servicePresentationState,
    required this.localControlBusy,
    required this.localPresentationBusy,
    required this.onExplain,
    required this.onOpenLocalServiceControls,
    required this.onHide,
    required this.onIgnore,
  });

  final DashboardBucket bucket;
  final DashboardCard card;
  final ContextualExplanationPresentation explanation;
  final LocalServicePresentationState servicePresentationState;
  final bool localControlBusy;
  final bool localPresentationBusy;
  final VoidCallback onExplain;
  final VoidCallback onOpenLocalServiceControls;
  final VoidCallback onHide;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: PopupMenuButton<_SubscriptionCardMenuAction>(
        key: ValueKey<String>(
          'service-card-actions-${bucket.name}-${card.serviceKey.value}',
        ),
        enabled: !(localControlBusy || localPresentationBusy),
        tooltip: 'More actions for ${card.title}',
        padding: EdgeInsets.zero,
        color: DashboardShellPalette.elevatedPaper,
        surfaceTintColor: Colors.transparent,
        icon: const Icon(Icons.more_horiz_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DashboardShellPalette.outlineStrong),
        ),
        onSelected: (action) {
          switch (action) {
            case _SubscriptionCardMenuAction.explain:
              onExplain();
              break;
            case _SubscriptionCardMenuAction.organize:
              onOpenLocalServiceControls();
              break;
            case _SubscriptionCardMenuAction.hide:
              onHide();
              break;
            case _SubscriptionCardMenuAction.ignore:
              onIgnore();
              break;
          }
        },
        itemBuilder: (context) => <PopupMenuEntry<_SubscriptionCardMenuAction>>[
          PopupMenuItem<_SubscriptionCardMenuAction>(
            key: ValueKey<String>(
              'open-card-explanation-${bucket.name}-${card.title}',
            ),
            value: _SubscriptionCardMenuAction.explain,
            child: Row(
              children: <Widget>[
                const Icon(Icons.help_outline_rounded, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(explanation.actionLabel)),
              ],
            ),
          ),
          PopupMenuItem<_SubscriptionCardMenuAction>(
            key: ValueKey<String>(
              'open-local-service-controls-${bucket.name}-${card.serviceKey.value}',
            ),
            value: _SubscriptionCardMenuAction.organize,
            child: Row(
              children: <Widget>[
                Icon(
                  servicePresentationState.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Organize')),
              ],
            ),
          ),
          PopupMenuItem<_SubscriptionCardMenuAction>(
            key: ValueKey<String>(
              'hide-card-action-${bucket.name}-${card.serviceKey.value}',
            ),
            value: _SubscriptionCardMenuAction.hide,
            child: const Row(
              children: <Widget>[
                Icon(Icons.visibility_off_outlined, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Hide')),
              ],
            ),
          ),
          PopupMenuItem<_SubscriptionCardMenuAction>(
            key: ValueKey<String>(
              'ignore-card-action-${card.serviceKey.value}',
            ),
            value: _SubscriptionCardMenuAction.ignore,
            child: const Row(
              children: <Widget>[
                Icon(Icons.do_not_disturb_on_outlined, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Ignore')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDecisionPassportCard extends StatelessWidget {
  const _ReviewDecisionPassportCard({
    required this.item,
    required this.descriptor,
    required this.presentation,
    required this.explanation,
    required this.isBusy,
    required this.onOpenDetails,
    required this.onExplain,
    required this.onIgnore,
    required this.onConfirm,
    required this.onMarkAsBenefit,
    required this.onEditDetails,
    required this.onDismiss,
  });

  final ReviewItem item;
  final ReviewItemActionDescriptor descriptor;
  final ReviewQueueItemPresentation presentation;
  final ContextualExplanationPresentation explanation;
  final bool isBusy;
  final VoidCallback onOpenDetails;
  final VoidCallback onExplain;
  final VoidCallback onIgnore;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkAsBenefit;
  final VoidCallback? onEditDetails;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final identity = _identityStyle(
      item.title,
      accentColor: DashboardShellPalette.caution,
    );
    final summary = _reviewCardSemantics(
      item,
      presentation: presentation,
      descriptor: descriptor,
    );
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        );
    final reasonStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardShellPalette.mutedInk,
          fontWeight: FontWeight.w600,
          height: 1.2,
        );
    final compactActionStyle = FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
    final compactOutlineStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    return Semantics(
      container: true,
      label: summary,
      child: DashboardPanel(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              Colors.white.withValues(alpha: 0.02),
              DashboardShellPalette.elevatedPaper,
            ),
            Color.alphaBlend(
              Colors.black.withValues(alpha: 0.16),
              DashboardShellPalette.elevatedPaper,
            ),
          ],
        ),
        backgroundColor: DashboardShellPalette.elevatedPaper,
        borderColor: DashboardShellPalette.outlineStrong,
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DashboardServiceAvatar(
                  key: ValueKey<String>('passport-avatar-${item.title}'),
                  monogram: identity.monogram,
                  foregroundColor: identity.foreground,
                  backgroundColor: identity.background,
                  borderColor: identity.border,
                  serviceKey: item.serviceKey.value,
                  sealColor: DashboardShellPalette.caution,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item.title, style: titleStyle),
                      const SizedBox(height: 4),
                      Text(
                        presentation.explanationDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: reasonStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ReviewDetailsButton(
                  targetKey: descriptor.targetKey,
                  title: item.title,
                  isBusy: isBusy,
                  onPressed: onOpenDetails,
                ),
                const SizedBox(width: 4),
                _ReviewActionOverflowButton(
                  title: item.title,
                  descriptor: descriptor,
                  explanation: explanation,
                  isBusy: isBusy,
                  onExplain: onExplain,
                  onIgnore: onIgnore,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (descriptor.canConfirm)
                  _ContextualActionSemantics(
                    label: 'Confirm ${item.title} as a paid subscription',
                    enabled: !isBusy,
                    child: FilledButton(
                      key: ValueKey<String>(
                        'confirm-review-action-${descriptor.targetKey}',
                      ),
                      style: compactActionStyle,
                      onPressed: isBusy ? null : onConfirm,
                      child: Text(
                        isBusy ? 'Working...' : presentation.confirmLabel!,
                      ),
                    ),
                  ),
                if (descriptor.canConfirm)
                  _ContextualActionSemantics(
                    label: 'Keep ${item.title} separate as a benefit or bundle',
                    enabled: !isBusy,
                    child: OutlinedButton(
                      key: ValueKey<String>(
                        'benefit-review-action-${descriptor.targetKey}',
                      ),
                      style: compactOutlineStyle,
                      onPressed: isBusy ? null : onMarkAsBenefit,
                      child: Text(
                        isBusy ? 'Working...' : presentation.benefitLabel!,
                      ),
                    ),
                  ),
                if (!descriptor.canConfirm)
                  _ContextualActionSemantics(
                    label: 'Edit review details for ${item.title}',
                    enabled: !isBusy,
                    child: FilledButton.tonal(
                      key: ValueKey<String>(
                        'edit-review-action-${descriptor.targetKey}',
                      ),
                      style: compactActionStyle,
                      onPressed: isBusy ? null : onEditDetails,
                      child: Text(
                        isBusy ? 'Working...' : presentation.editLabel,
                      ),
                    ),
                  ),
                _ContextualActionSemantics(
                  label: 'Mark ${item.title} as not a subscription',
                  enabled: !isBusy,
                  child: OutlinedButton(
                    key: ValueKey<String>(
                      'dismiss-review-action-${descriptor.targetKey}',
                    ),
                    style: compactOutlineStyle,
                    onPressed: isBusy ? null : onDismiss,
                    child: Text(
                      isBusy ? 'Working...' : presentation.dismissLabel,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDetailsButton extends StatelessWidget {
  const _ReviewDetailsButton({
    required this.targetKey,
    required this.title,
    required this.isBusy,
    required this.onPressed,
  });

  final String targetKey;
  final String title;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Details',
      child: IconButton(
        key: ValueKey<String>('open-review-details-$targetKey'),
        onPressed: isBusy ? null : onPressed,
        tooltip: 'Details for $title',
        icon: const Icon(Icons.help_outline_rounded),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: DashboardShellPalette.nestedPaper,
          foregroundColor: DashboardShellPalette.caution,
          disabledBackgroundColor: DashboardShellPalette.nestedPaper,
          disabledForegroundColor:
              DashboardShellPalette.mutedInk.withValues(alpha: 0.7),
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }
}

class _ReviewItemDetailsSheet extends StatelessWidget {
  const _ReviewItemDetailsSheet({
    required this.item,
    required this.descriptor,
    required this.presentation,
    required this.explanation,
    required this.isBusy,
    required this.onDismiss,
    required this.onEditDetails,
    required this.onExplain,
    this.onConfirm,
    this.onMarkAsBenefit,
  });

  final ReviewItem item;
  final ReviewItemActionDescriptor descriptor;
  final ReviewQueueItemPresentation presentation;
  final ContextualExplanationPresentation explanation;
  final bool isBusy;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkAsBenefit;
  final VoidCallback onDismiss;
  final VoidCallback onEditDetails;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final accentColor = DashboardShellPalette.caution;
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
              'review-item-details-sheet-${descriptor.targetKey}'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.explanationDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              presentation.explanationDescription,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _ReviewDecisionActionsBlock(
                  framed: false,
                  title: null,
                  helper: null,
                  accentColor: accentColor,
                  children: <Widget>[
                    if (onConfirm != null)
                      _ContextualActionSemantics(
                        label: 'Confirm ${item.title} as a paid subscription',
                        enabled: !isBusy,
                        child: FilledButton(
                          key: ValueKey<String>(
                            'review-details-confirm-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onConfirm,
                          child: Text(
                            isBusy ? 'Working...' : presentation.confirmLabel!,
                          ),
                        ),
                      ),
                    if (onMarkAsBenefit != null)
                      _ContextualActionSemantics(
                        label:
                            'Keep ${item.title} separate as a benefit or bundle',
                        enabled: !isBusy,
                        child: OutlinedButton(
                          key: ValueKey<String>(
                            'review-details-benefit-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onMarkAsBenefit,
                          child: Text(
                            isBusy ? 'Working...' : presentation.benefitLabel!,
                          ),
                        ),
                      ),
                    if (onConfirm == null)
                      _ContextualActionSemantics(
                        label: 'Edit review details for ${item.title}',
                        enabled: !isBusy,
                        child: FilledButton(
                          key: ValueKey<String>(
                            'review-details-edit-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onEditDetails,
                          child: Text(
                            isBusy ? 'Working...' : presentation.editLabel,
                          ),
                        ),
                      ),
                    _ContextualActionSemantics(
                      label: 'Mark ${item.title} as not a subscription',
                      enabled: !isBusy,
                      child: OutlinedButton(
                        key: ValueKey<String>(
                          'review-details-dismiss-${descriptor.targetKey}',
                        ),
                        onPressed: isBusy ? null : onDismiss,
                        child: Text(
                          isBusy ? 'Working...' : presentation.dismissLabel,
                        ),
                      ),
                    ),
                    if (onConfirm != null)
                      _ContextualActionSemantics(
                        label: 'Edit review details for ${item.title}',
                        enabled: !isBusy,
                        child: TextButton(
                          key: ValueKey<String>(
                            'review-details-edit-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onEditDetails,
                          child: Text(
                            isBusy ? 'Working...' : presentation.editLabel,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _ReviewEvidencePanel(
                  presentation: presentation,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewDecisionActionsBlock extends StatelessWidget {
  const _ReviewDecisionActionsBlock({
    required this.title,
    required this.helper,
    required this.children,
    this.framed = false,
    this.accentColor = DashboardShellPalette.caution,
  });

  final String? title;
  final String? helper;
  final List<Widget> children;
  final bool framed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isStackPreferred = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null && title!.isNotEmpty) ...<Widget>[
          Text(
            title!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
        if (helper != null && helper!.isNotEmpty) ...<Widget>[
          if (title != null && title!.isNotEmpty) const SizedBox(height: 4),
          Text(
            helper!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  height: 1.24,
                ),
          ),
        ],
        if ((title != null && title!.isNotEmpty) ||
            (helper != null && helper!.isNotEmpty))
          const SizedBox(height: 10),
        if (isStackPreferred)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .expand((w) => [w, const SizedBox(height: 10)])
                .toList()
              ..removeLast(),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: children,
          ),
      ],
    );

    if (!framed) {
      return content;
    }

    return DashboardPanel(
      backgroundColor: DashboardShellPalette.nestedPaper,
      borderColor: accentColor.withValues(alpha: 0.18),
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      child: content,
    );
  }
}

class _ReviewEvidencePanel extends StatefulWidget {
  const _ReviewEvidencePanel({
    required this.presentation,
    required this.accentColor,
  });

  final ReviewQueueItemPresentation presentation;
  final Color accentColor;

  @override
  State<_ReviewEvidencePanel> createState() => _ReviewEvidencePanelState();
}

class _ReviewEvidencePanelState extends State<_ReviewEvidencePanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      backgroundColor: DashboardShellPalette.nestedPaper,
      borderColor: widget.accentColor.withValues(alpha: 0.18),
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: InkWell(
        key: const ValueKey<String>('review-evidence-panel'),
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Why SubWatch flagged this',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open only if you want the details.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: widget.accentColor,
                ),
              ],
            ),
            if (_isExpanded) ...<Widget>[
              const SizedBox(height: 12),
              _ReviewEvidenceBullet(
                title: widget.presentation.rationaleLabel,
                body: widget.presentation.rationale,
                accentColor: widget.accentColor,
              ),
              const SizedBox(height: 10),
              _ReviewEvidenceBullet(
                title: widget.presentation.whyFlaggedTitle,
                body: widget.presentation.whyFlagged,
                accentColor: widget.accentColor,
              ),
              const SizedBox(height: 10),
              _ReviewEvidenceBullet(
                title: widget.presentation.whyNotConfirmedTitle,
                body: widget.presentation.whyNotConfirmed,
                accentColor: widget.accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewEvidenceBullet extends StatelessWidget {
  const _ReviewEvidenceBullet({
    required this.title,
    required this.body,
    required this.accentColor,
  });

  final String title;
  final String body;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.ink,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewActionOverflowButton extends StatelessWidget {
  const _ReviewActionOverflowButton({
    required this.title,
    required this.descriptor,
    required this.explanation,
    required this.isBusy,
    required this.onExplain,
    required this.onIgnore,
  });

  final String title;
  final ReviewItemActionDescriptor descriptor;
  final ContextualExplanationPresentation explanation;
  final bool isBusy;
  final VoidCallback onExplain;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: PopupMenuButton<_ReviewCardMenuAction>(
        key: ValueKey<String>('review-card-actions-${descriptor.targetKey}'),
        enabled: !isBusy,
        tooltip: 'More actions for $title',
        padding: EdgeInsets.zero,
        color: DashboardShellPalette.elevatedPaper,
        surfaceTintColor: Colors.transparent,
        icon: const Icon(Icons.more_horiz_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DashboardShellPalette.outlineStrong),
        ),
        onSelected: (action) {
          switch (action) {
            case _ReviewCardMenuAction.explain:
              onExplain();
              break;
            case _ReviewCardMenuAction.ignore:
              onIgnore();
              break;
          }
        },
        itemBuilder: (context) => <PopupMenuEntry<_ReviewCardMenuAction>>[
          PopupMenuItem<_ReviewCardMenuAction>(
            key: ValueKey<String>(
                'open-review-explanation-${descriptor.targetKey}'),
            value: _ReviewCardMenuAction.explain,
            child: Row(
              children: <Widget>[
                const Icon(Icons.help_outline_rounded, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(explanation.actionLabel)),
              ],
            ),
          ),
          PopupMenuItem<_ReviewCardMenuAction>(
            key: ValueKey<String>(
                'ignore-review-item-action-${descriptor.targetKey}'),
            value: _ReviewCardMenuAction.ignore,
            child: const Row(
              children: <Widget>[
                Icon(Icons.do_not_disturb_on_outlined, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Hide on this phone')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextualExplanationSheet extends StatelessWidget {
  const _ContextualExplanationSheet({
    required this.presentation,
  });

  final ContextualExplanationPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final stackedHeader = MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('contextual-explanation-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        presentation.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              presentation.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              presentation.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _TrustSheetSection(
                  title: 'Why SubWatch shows this',
                  items: presentation.bullets,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetCloseButton extends DashboardSheetCloseButton {
  const _SheetCloseButton({
    required super.onPressed,
  });
}

class _SheetHandle extends DashboardSheetHandle {
  const _SheetHandle();
}

class _StatusMetaBadge extends StatelessWidget {
  const _StatusMetaBadge({
    required this.label,
    required this.valueKey,
  });

  final String label;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardShellPalette.nestedPaper.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DashboardShellPalette.mutedInk.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        key: valueKey,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DashboardShellPalette.mutedInk,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
            ),
      ),
    );
  }
}

class _SourceStatusMetadataCluster extends StatelessWidget {
  const _SourceStatusMetadataCluster({
    required this.status,
  });

  final RuntimeLocalMessageSourceStatus status;

  @override
  Widget build(BuildContext context) {
    final showFreshnessLabel =
        status.freshnessLabel.trim() != status.provenanceTitle.trim();
    final labels = <String>[
      'Current view ${status.provenanceTitle}',
      if (showFreshnessLabel) 'Freshness ${status.freshnessLabel}',
      if (status.hasLocalModifications &&
          status.localModificationsLabel != null)
        status.localModificationsLabel!,
    ];

    return Semantics(
      key: const ValueKey<String>('runtime-source-metadata-semantics'),
      label: labels.join('. '),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 10,
          runSpacing: 3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (showFreshnessLabel) ...<Widget>[
              Text(
                '\u2022',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                    ),
              ),
              Text(
                status.freshnessLabel,
                key: const ValueKey<String>('runtime-freshness-label'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            _StatusMetaBadge(
              label: status.provenanceTitle,
              valueKey: const ValueKey<String>('runtime-provenance-title'),
            ),
            if (status.hasLocalModifications &&
                status.localModificationsLabel != null)
              _StatusMetaBadge(
                label: status.localModificationsLabel!,
                valueKey: const ValueKey<String>(
                  'runtime-local-state-label',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContextualActionSemantics extends StatelessWidget {
  const _ContextualActionSemantics({
    required this.label,
    this.enabled = true,
    required this.child,
  });

  final String label;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }
}

class _BucketStyle {
  const _BucketStyle({
    required this.badgeLabel,
    required this.background,
    required this.border,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final String badgeLabel;
  final Color background;
  final Color border;
  final Color badgeBackground;
  final Color badgeForeground;
}

class _PassportIdentityStyle {
  const _PassportIdentityStyle({
    required this.monogram,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String monogram;
  final Color background;
  final Color foreground;
  final Color border;
}

_PassportIdentityStyle _identityStyle(
  String title, {
  required Color accentColor,
}) {
  const palettes = <(Color, Color, Color)>[
    (Color(0xFF243028), Color(0xFF9BD4BC), Color(0xFF395247)),
    (Color(0xFF26232F), Color(0xFFBDC7DD), Color(0xFF413D50)),
    (Color(0xFF30231D), Color(0xFFE4B27B), Color(0xFF4A372C)),
    (Color(0xFF25291F), Color(0xFFB9C98B), Color(0xFF3C4530)),
    (Color(0xFF312327), Color(0xFFD7A7AE), Color(0xFF4A363A)),
  ];
  final index =
      title.runes.fold<int>(0, (sum, rune) => sum + rune) % palettes.length;
  final palette = palettes[index];
  return _PassportIdentityStyle(
    monogram: _monogramForTitle(title),
    background: palette.$1,
    foreground: palette.$2,
    border: Color.alphaBlend(
      accentColor.withValues(alpha: 0.12),
      palette.$3,
    ),
  );
}

IconData _sourceIconForTone(RuntimeLocalMessageSourceTone tone) {
  switch (tone) {
    case RuntimeLocalMessageSourceTone.demo:
      return Icons.visibility_outlined;
    case RuntimeLocalMessageSourceTone.fresh:
      return Icons.sms_rounded;
    case RuntimeLocalMessageSourceTone.restored:
      return Icons.history_rounded;
    case RuntimeLocalMessageSourceTone.caution:
      return Icons.lock_outline_rounded;
    case RuntimeLocalMessageSourceTone.unavailable:
      return Icons.portable_wifi_off_rounded;
  }
}

String _summarizeFindingTitles(
  Iterable<String> titles, {
  required String singularLabel,
  required String pluralLabel,
}) {
  final normalizedTitles = titles
      .map((title) => title.trim())
      .where((title) => title.isNotEmpty)
      .toList(growable: false);

  if (normalizedTitles.isEmpty) {
    return '';
  }

  if (normalizedTitles.length == 1) {
    return '${normalizedTitles.first} \u00B7 1 $singularLabel.';
  }

  if (normalizedTitles.length == 2) {
    return '${normalizedTitles.first} and ${normalizedTitles.last} \u00B7 2 $pluralLabel.';
  }

  return '${normalizedTitles.first}, ${normalizedTitles[1]}, and ${normalizedTitles.length - 2} more \u00B7 ${normalizedTitles.length} $pluralLabel.';
}

String _previewCountLabel(int count) {
  return count == 1 ? '1 item' : '$count items';
}

String _joinPreviewTitles(List<String> titles) {
  if (titles.isEmpty) {
    return 'Sample items';
  }
  if (titles.length == 1) {
    return titles.first;
  }
  return '${titles.first} and ${titles[1]}';
}

String _fallbackAmountLabel(DashboardBucket bucket) {
  switch (bucket) {
    case DashboardBucket.confirmedSubscriptions:
      return 'Not found yet';
    case DashboardBucket.needsReview:
      return 'Not visible yet';
    case DashboardBucket.trialsAndBenefits:
      return 'Included access';
    case DashboardBucket.hidden:
      return 'Not available';
  }
}

String _fallbackRenewalLabel(DashboardBucket bucket) {
  switch (bucket) {
    case DashboardBucket.confirmedSubscriptions:
    case DashboardBucket.needsReview:
      return 'Date not clear yet';
    case DashboardBucket.trialsAndBenefits:
      return 'Renewal date not shown';
    case DashboardBucket.hidden:
      return 'Not available';
  }
}

String _fallbackFrequencyLabel(DashboardBucket bucket) {
  switch (bucket) {
    case DashboardBucket.confirmedSubscriptions:
    case DashboardBucket.needsReview:
      return 'Cycle not clear yet';
    case DashboardBucket.trialsAndBenefits:
      return 'Included with another plan';
    case DashboardBucket.hidden:
      return 'Not available';
  }
}

String _subscriptionCardDueLabel(String renewalLabel) {
  switch (renewalLabel) {
    case 'Date not clear yet':
    case 'Renewal date not shown':
    case 'No renewal date':
    case 'Not available':
      return renewalLabel;
  }
  return 'Due $renewalLabel';
}

String _dueSoonPreviewDescription(
  String serviceTitle,
  String renewalDateLabel,
  String? amountLabel,
) {
  if (amountLabel == null) {
    return '$serviceTitle appears here once the next renewal date is clear on $renewalDateLabel.';
  }
  return '$serviceTitle appears here once the next renewal date is clear on $renewalDateLabel for $amountLabel.';
}

String _demoDueSoonFallback(
  List<DashboardCard> confirmedCards,
  DateTime recordedAt,
) {
  if (confirmedCards.isEmpty) {
    return 'Renewals with clear dates appear here before they are due.';
  }

  final previewCard = confirmedCards.first;
  final previewDate =
      _formatPreviewDate(recordedAt.add(const Duration(days: 5)));
  final amountLabel = _extractVisibleAmountLabel(previewCard.subtitle);
  if (amountLabel == null) {
    return 'Example: ${previewCard.title} would appear here around $previewDate once a renewal date is clear.';
  }
  return 'Example: ${previewCard.title} on $previewDate for $amountLabel once the next renewal date is clear.';
}

String? _extractVisibleAmountLabel(String subtitle) {
  final match = RegExp(
    '(?:\u20B9\s*|Rs\.?\s*|INR\s*|Rupees\s*)([0-9]+(?:,[0-9]{3})*(?:\.[0-9]+)?)\b',
    caseSensitive: false,
  ).firstMatch(subtitle);
  if (match == null) {
    return null;
  }
  return '\u20B9${match.group(1)!}';
}

String _formatPreviewDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]}';
}

String _formatHomeStatusTimestamp(
  DateTime value, {
  required DateTime now,
}) {
  final sameDay = value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = value.year == yesterday.year &&
      value.month == yesterday.month &&
      value.day == yesterday.day;
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  final timeLabel = '$hour:$minute $period';
  if (sameDay) {
    return 'today $timeLabel';
  }
  if (isYesterday) {
    return 'yesterday $timeLabel';
  }
  return '${_formatManualDate(value)} $timeLabel';
}

String _subscriptionRowSemantics(
  DashboardCard card, {
  required _SubscriptionCardMetadata metadata,
  required _BucketStyle style,
  required LocalServicePresentationState servicePresentationState,
}) {
  final visibleTitle = servicePresentationState.displayTitle;
  final amount = metadata.amountLabel;
  final frequency = card.subtitle; 
  
  final parts = <String>[
    visibleTitle,
    style.badgeLabel,
    if (amount.isNotEmpty) 'Amount $amount',
    if (frequency.isNotEmpty) frequency,
    if (metadata.bundledSummary != null) metadata.bundledSummary!,
    if (servicePresentationState.isPinned) 'Pinned',
    'Double tap for details',
  ];
  return '${parts.join('. ')}.';


}

  final amount = _formatManualSubscriptionAmount(entry.amountInMinorUnits);
  final cycle = entry.billingCycle == ManualSubscriptionBillingCycle.monthly
      ? 'Monthly'
      : 'Yearly';

  final parts = <String>[
    entry.serviceName,
    'Added by you',
    if (amount != null) 'Amount $amount',
    cycle,
    'Double tap for details',
  ];
  return '${parts.join('. ')}.';


String _reviewCardSemantics(
  ReviewItem item, {
  required ReviewQueueItemPresentation presentation,
  required ReviewItemActionDescriptor descriptor,
}) {
  final statusLabel =
      descriptor.canConfirm ? 'Needs your review' : 'Needs a clearer service';
  final explanation = presentation.explanationDescription;

  final parts = <String>[
    item.title,
    statusLabel,
    if (explanation.isNotEmpty) explanation,
    'Double tap for details',
  ];
  return '${parts.join('. ')}.';

}


String _manualSubscriptionSubtitle(ManualSubscriptionEntry entry) {
  final parts = <String>[
    entry.billingCycle == ManualSubscriptionBillingCycle.monthly
        ? 'Monthly'
        : 'Yearly',
  ];
  final amount = _formatManualSubscriptionAmount(entry.amountInMinorUnits);
  if (amount != null) {
    parts.add(amount);
  }
  if (entry.hasNextRenewalDate) {
    parts.add('Renews ${_formatManualDate(entry.nextRenewalDate!)}');
  }
  if (entry.hasPlanLabel) {
    parts.add(entry.planLabel!);
  }
  return parts.join(' \u00B7 ');
}

String _manualSubscriptionSemanticsSummary(ManualSubscriptionEntry entry) {
  final parts = <String>[
    entry.billingCycle == ManualSubscriptionBillingCycle.monthly
        ? 'Monthly'
        : 'Yearly',
  ];
  final amount = _formatManualSubscriptionAmount(entry.amountInMinorUnits);
  if (amount != null) {
    parts.add(amount);
  }
  if (entry.hasNextRenewalDate) {
    parts.add('Renews ${_formatManualDate(entry.nextRenewalDate!)}');
  }
  if (entry.hasPlanLabel) {
    parts.add(entry.planLabel!);
  }
  return parts.join(', ');
}

String _manualSubscriptionBillingSummary(ManualSubscriptionEntry entry) {
  final cycle = entry.billingCycle == ManualSubscriptionBillingCycle.monthly
      ? 'Monthly'
      : 'Yearly';
  final amount = _formatManualSubscriptionAmount(entry.amountInMinorUnits);
  if (amount == null) {
    return cycle;
  }
  return '$cycle \u00B7 $amount';
}

String _manualEntryImprovementCopy(ManualSubscriptionEntry entry) {
  if (!entry.hasAmount && !entry.hasNextRenewalDate) {
    return 'Add an amount if you want this entry included in your estimate, and add a renewal date if you want it to appear in renewals and reminders.';
  }
  if (!entry.hasAmount) {
    return 'Add an amount if you want this entry included in your estimate.';
  }
  return 'Add a renewal date if you want this entry to appear in renewals and reminders.';
}

String? _formatManualSubscriptionAmount(int? amountInMinorUnits) {
  if (amountInMinorUnits == null) {
    return null;
  }

  final wholeUnits = amountInMinorUnits ~/ 100;
  final fractionalUnits = amountInMinorUnits % 100;
  if (fractionalUnits == 0) {
    return '\u20B9$wholeUnits';
  }
  final fraction = fractionalUnits.toString().padLeft(2, '0');
  return '\u20B9$wholeUnits.$fraction';
}

String _formatManualAmountInput(int amountInMinorUnits) {
  final wholeUnits = amountInMinorUnits ~/ 100;
  final fractionalUnits = amountInMinorUnits % 100;
  if (fractionalUnits == 0) {
    return wholeUnits.toString();
  }
  return '$wholeUnits.${fractionalUnits.toString().padLeft(2, '0')}';
}

String _formatManualDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[value.month - 1];
  return '${value.day} $month ${value.year}';
}

String _monogramForTitle(String title) {
  final parts = title
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'SK';
  }
  if (parts.length == 1) {
    final word = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (word.length >= 2) {
      return word.substring(0, 2).toUpperCase();
    }
    return word.toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
