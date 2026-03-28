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
              if (!reduceMotion) const CircularProgressIndicator(),
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
    final theme = Theme.of(context);
    final type = context.dashboardType;
    final heroBadge = _heroBadge();
    final showPrimaryAction = onPrimaryAction != null &&
        (!hasHeroData ||
            sourceStatus.tone != RuntimeLocalMessageSourceTone.fresh);
    final supportBadges = _heroSupportBadges();

    return DashboardPanel(
      key: const ValueKey<String>('totals-summary-card'),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF2C1F18),
          DashboardShellPalette.paper,
        ],
      ),
      borderColor: DashboardShellPalette.outlineStrong,
      radius: DashboardRadii.prominentCard,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    DashboardBadge(
                      label: heroBadge.$1,
                      icon: heroBadge.$2,
                      backgroundColor: heroBadge.$3,
                      foregroundColor: heroBadge.$4,
                    ),
                    if (sourceStatus.tone == RuntimeLocalMessageSourceTone.demo)
                      const DashboardBadge(
                        label: 'Example data',
                        icon: Icons.visibility_outlined,
                        backgroundColor: DashboardShellPalette.nestedPaper,
                        foregroundColor: DashboardShellPalette.mutedInk,
                      ),
                  ],
                ),
              ),
              if (!hasHeroData)
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: DashboardShellPalette.elevatedPaper,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: DashboardShellPalette.outlineStrong,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const SubWatchBrandMark(size: 40, showBase: true),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasHeroData) ...<Widget>[
            Text(
              _emptyHeadline(),
              key: const ValueKey<String>('spend-hero-empty-headline'),
              style: type.screenTitle.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emptySupportCopy(),
              key: const ValueKey<String>('spend-hero-empty-support'),
              style: type.body.copyWith(
                color: DashboardShellPalette.softInk,
                height: 1.36,
              ),
            ),
          ] else ...<Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _heroPrimaryValue(),
                key: const ValueKey<String>('spend-hero-amount'),
                style: (presentation.hasEstimatedSpend
                        ? theme.textTheme.displayMedium
                        : theme.textTheme.displayLarge)
                    ?.copyWith(
                  color: presentation.hasEstimatedSpend
                      ? DashboardShellPalette.accent
                      : DashboardShellPalette.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: presentation.hasEstimatedSpend ? -0.55 : -1.1,
                  height: 0.92,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _heroPrimaryCaption(),
              key: const ValueKey<String>('spend-hero-confirmed-chip'),
              style: type.rowTitle.copyWith(
                fontWeight: FontWeight.w700,
                color: DashboardShellPalette.softInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              presentation.summaryCopy,
              style: type.supporting.copyWith(
                color: DashboardShellPalette.mutedInk,
                height: 1.32,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                _lastScanLine(provenance, now: now),
                key: const ValueKey<String>('spend-hero-last-scan'),
                style: type.meta.copyWith(
                  color: DashboardShellPalette.mutedInk,
                ),
              ),
              ...supportBadges,
            ],
          ),
          if (showPrimaryAction) ...<Widget>[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey<String>('sync-with-sms-button'),
                onPressed: onPrimaryAction,
                icon: Icon(
                  sourceStatus.tone == RuntimeLocalMessageSourceTone.caution
                      ? Icons.lock_open_rounded
                      : Icons.sync_rounded,
                ),
                label: Text(sourceStatus.actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String, IconData, Color, Color) _heroBadge() {
    if (sourceStatus.tone == RuntimeLocalMessageSourceTone.demo) {
      return (
        'Sample preview',
        Icons.visibility_outlined,
        DashboardShellPalette.statusBlueSoft,
        DashboardShellPalette.statusBlue,
      );
    }
    if (sourceStatus.tone == RuntimeLocalMessageSourceTone.caution) {
      return (
        'SMS access off',
        Icons.lock_outline_rounded,
        DashboardShellPalette.cautionSoft,
        DashboardShellPalette.caution,
      );
    }
    if (presentation.hasEstimatedSpend) {
      return (
        presentation.estimateBadgeLabel,
        Icons.auto_graph_rounded,
        DashboardShellPalette.accentSoft,
        DashboardShellPalette.accent,
      );
    }
    if (presentation.activePaidCount > 0) {
      return (
        'Amounts pending',
        Icons.receipt_long_outlined,
        DashboardShellPalette.nestedPaper,
        DashboardShellPalette.softInk,
      );
    }
    return (
      'Subscription reality',
      Icons.verified_outlined,
      DashboardShellPalette.nestedPaper,
      DashboardShellPalette.softInk,
    );
  }

  List<Widget> _heroSupportBadges() {
    final badges = <Widget>[
      DashboardBadge(
        label: presentation.activePaidCount == 1
            ? '1 confirmed'
            : '${presentation.activePaidCount} confirmed',
        backgroundColor: DashboardShellPalette.nestedPaper,
        foregroundColor: DashboardShellPalette.softInk,
      ),
    ];

    if (presentation.reviewCount > 0) {
      badges.add(
        DashboardBadge(
          label: presentation.reviewCount == 1
              ? '1 in review'
              : '${presentation.reviewCount} in review',
          backgroundColor: DashboardShellPalette.cautionSoft,
          foregroundColor: DashboardShellPalette.caution,
        ),
      );
    } else if (presentation.totalMissingAmountSources > 0) {
      badges.add(
        DashboardBadge(
          label: presentation.totalMissingAmountSources == 1
              ? '1 amount pending'
              : '${presentation.totalMissingAmountSources} amounts pending',
          backgroundColor: DashboardShellPalette.nestedPaper,
          foregroundColor: DashboardShellPalette.mutedInk,
        ),
      );
    }

    return badges;
  }

  String _heroPrimaryValue() {
    if (presentation.hasEstimatedSpend) {
      return presentation.monthlyTotalValueLabel;
    }
    return presentation.activePaidValueLabel;
  }

  String _heroPrimaryCaption() {
    if (presentation.hasEstimatedSpend) {
      return presentation.activePaidCount == 1
          ? '1 confirmed subscription'
          : '${presentation.activePaidCount} confirmed subscriptions';
    }
    return presentation.activePaidCaption;
  }

  String _emptyHeadline() {
    if (presentation.reviewCount > 0) {
      return 'Nothing confirmed yet';
    }
    switch (sourceStatus.tone) {
      case RuntimeLocalMessageSourceTone.caution:
        return 'Turn on SMS access';
      case RuntimeLocalMessageSourceTone.restored:
        return 'Check again for a fresh view';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'Subscriptions appear after a scan';
      case RuntimeLocalMessageSourceTone.demo:
        return 'This is a safe preview';
      case RuntimeLocalMessageSourceTone.fresh:
        return 'No paid subscriptions confirmed yet';
    }
  }

  String _emptySupportCopy() {
    if (presentation.reviewCount > 0) {
      return presentation.reviewCount == 1
          ? '1 item is waiting in Review, so Home stays conservative until the signal is clearer.'
          : '${presentation.reviewCount} items are waiting in Review, so Home stays conservative until the signal is clearer.';
    }
    switch (sourceStatus.tone) {
      case RuntimeLocalMessageSourceTone.caution:
        return 'Saved results stay visible, but you need SMS access for a fresh on-device scan.';
      case RuntimeLocalMessageSourceTone.restored:
        return 'Your last saved results stayed in place. Run another scan when you want a fresher view.';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'This phone cannot scan SMS, so Home only shows what is already available locally.';
      case RuntimeLocalMessageSourceTone.demo:
        return 'Scan this phone to replace the example data with your own subscription reality.';
      case RuntimeLocalMessageSourceTone.fresh:
        return 'Confirmed subscriptions appear here only after SubWatch sees billing proof strong enough to trust.';
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
    required this.subscriptionCount,
    required this.reviewCount,
    required this.sourceStatus,
    required this.onReview,
    required this.onSync,
    required this.onOpenRenewals,
    required this.onOpenSubscriptions,
    required this.onOpenSettings,
  });

  final _HomeActionCopy? copy;
  final int subscriptionCount;
  final int reviewCount;
  final RuntimeLocalMessageSourceStatus sourceStatus;
  final Future<void> Function() onReview;
  final Future<void> Function() onSync;
  final Future<void> Function() onOpenRenewals;
  final Future<void> Function() onOpenSubscriptions;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final urgentTone = copy?.primaryActionKind == _HomeActionKind.review ||
            copy?.primaryActionKind == _HomeActionKind.sync
        ? _HomePathwayRowTone.caution
        : _HomePathwayRowTone.neutral;

    return DashboardPanel(
      key: const ValueKey<String>('home-action-strip'),
      backgroundColor: DashboardShellPalette.elevatedPaper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: DashboardRadii.card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Quick paths',
            style: type.sectionTitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Review what needs attention or go deeper into your full list and controls.',
            style: type.supporting.copyWith(
              color: DashboardShellPalette.mutedInk,
              height: 1.3,
            ),
          ),
          if (copy != null) ...<Widget>[
            const SizedBox(height: 14),
            _HomePathwayRow(
              title: copy!.title,
              subtitle: copy!.badgeLabel,
              icon: copy!.badgeIcon,
              tone: urgentTone,
              keyValue: const ValueKey<String>('home-action-primary-action'),
              badgeLabel: copy!.primaryActionLabel,
              onTap: switch (copy!.primaryActionKind) {
                _HomeActionKind.review => onReview,
                _HomeActionKind.sync => onSync,
                _HomeActionKind.renewals => onOpenRenewals,
              },
            ),
          ],
          const SizedBox(height: 14),
          _InsetListGroup(
            children: <Widget>[
              _HomePathwayRow(
                keyValue: const ValueKey<String>('home-pathway-subscriptions'),
                title: 'Subscriptions',
                subtitle: subscriptionCount == 0
                    ? 'Open your full list'
                    : subscriptionCount == 1
                        ? '1 visible subscription or included service'
                        : '$subscriptionCount visible subscriptions or included services',
                icon: Icons.subscriptions_rounded,
                badgeLabel: subscriptionCount == 0 ? null : '$subscriptionCount',
                onTap: onOpenSubscriptions,
              ),
              _HomePathwayRow(
                keyValue: const ValueKey<String>('home-pathway-review'),
                title: 'Review',
                subtitle: reviewCount == 0
                    ? 'Nothing waiting right now'
                    : reviewCount == 1
                        ? '1 item waiting for your decision'
                        : '$reviewCount items waiting for your decision',
                icon: Icons.fact_check_rounded,
                tone: reviewCount > 0
                    ? _HomePathwayRowTone.caution
                    : _HomePathwayRowTone.neutral,
                badgeLabel: reviewCount == 0 ? null : '$reviewCount',
                onTap: onReview,
              ),
              _HomePathwayRow(
                keyValue: const ValueKey<String>('home-pathway-settings'),
                title: 'Controls',
                subtitle: _settingsSubtitle(),
                icon: Icons.tune_rounded,
                tone: sourceStatus.tone == RuntimeLocalMessageSourceTone.caution
                    ? _HomePathwayRowTone.caution
                    : _HomePathwayRowTone.neutral,
                badgeLabel: sourceStatus.tone == RuntimeLocalMessageSourceTone.caution
                    ? 'Off'
                    : null,
                onTap: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _settingsSubtitle() {
    switch (sourceStatus.tone) {
      case RuntimeLocalMessageSourceTone.caution:
        return 'SMS access is off on this phone';
      case RuntimeLocalMessageSourceTone.demo:
        return 'Permissions, reminders, and local controls';
      case RuntimeLocalMessageSourceTone.restored:
        return 'Refresh, reminders, labels, and local controls';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'Device limitations and local controls';
      case RuntimeLocalMessageSourceTone.fresh:
        return 'Labels, reminders, and local controls';
    }
  }
}

enum _HomePathwayRowTone {
  neutral,
  caution,
}

class _HomePathwayRow extends StatelessWidget {
  const _HomePathwayRow({
    required this.keyValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badgeLabel,
    this.tone = _HomePathwayRowTone.neutral,
  });

  final Key keyValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final Future<void> Function() onTap;
  final String? badgeLabel;
  final _HomePathwayRowTone tone;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final foreground = tone == _HomePathwayRowTone.caution
        ? DashboardShellPalette.caution
        : DashboardShellPalette.softInk;
    final background = tone == _HomePathwayRowTone.caution
        ? DashboardShellPalette.cautionSoft
        : DashboardShellPalette.nestedPaper;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: keyValue,
        onTap: () async {
          await onTap();
        },
        borderRadius: BorderRadius.circular(DashboardRadii.button),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tone == _HomePathwayRowTone.caution
                        ? DashboardShellPalette.caution.withValues(alpha: 0.28)
                        : DashboardShellPalette.outline,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 18,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: type.rowTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: type.supporting.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (badgeLabel != null)
                DashboardBadge(
                  label: badgeLabel!,
                  backgroundColor: background,
                  foregroundColor: foreground,
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DashboardShellPalette.mutedInk,
                ),
            ],
          ),
        ),
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
      case RuntimeLocalMessageSourceTone.demo:
      case RuntimeLocalMessageSourceTone.restored:
        // Handled by the Hero CTA or App Bar actions to reduce first-fold noise.
        return null;
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
    final type = context.dashboardType;
    final dueSoonServiceKeys =
        dueSoon.items.map((item) => item.serviceKey).toSet();
    final laterRenewals = reminderItems
        .where((item) => !dueSoonServiceKeys.contains(item.renewal.serviceKey))
        .toList(growable: false);
    final visibleUpcomingItems =
        dueSoon.hasItems ? laterRenewals : reminderItems;
    final summaryLine = dueSoon.hasItems
        ? dueSoon.summaryCopy
        : upcomingRenewals.hasItems
            ? upcomingRenewals.summaryCopy
            : 'Renewal dates appear here once SubWatch can read them clearly.';

    return DashboardPanel(
      key: const ValueKey<String>('home-renewals-zone'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outline,
      radius: DashboardRadii.card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Coming up',
            style: type.sectionTitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            summaryLine,
            style: type.supporting.copyWith(
              color: DashboardShellPalette.mutedInk,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          if (!dueSoon.hasItems && visibleUpcomingItems.isEmpty)
            const DashboardEmptyState(
              title: 'Nothing due soon',
              message: 'Renewals appear here once dates are clear.',
              icon: Icons.schedule_outlined,
            )
          else ...<Widget>[
            if (dueSoon.hasItems) ...<Widget>[
              Text(
                'Due soon',
                style: type.meta.copyWith(
                  color: DashboardShellPalette.caution,
                  fontWeight: FontWeight.w800,
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
                const Divider(color: DashboardShellPalette.divider),
                const SizedBox(height: 12),
              ],
              Text(
                dueSoon.hasItems ? 'Later' : 'Upcoming renewals',
                style: type.meta.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  fontWeight: FontWeight.w800,
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
        ],
      ),
    );
  }
}

class _HomeInsightCard extends StatelessWidget {
  const _HomeInsightCard({
    required this.sourceStatus,
    required this.totalsSummary,
    required this.data,
    required this.onOpenTrustSheet,
  });

  final RuntimeLocalMessageSourceStatus sourceStatus;
  final DashboardTotalsSummaryPresentation totalsSummary;
  final RuntimeDashboardSnapshot data;
  final VoidCallback onOpenTrustSheet;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final insight = _HomeInsightState.fromSnapshot(
      data,
      sourceStatus: sourceStatus,
      totalsSummary: totalsSummary,
    );

    return DashboardPanel(
      key: const ValueKey<String>('product-guidance-panel'),
      backgroundColor: DashboardShellPalette.elevatedPaper,
      borderColor: insight.borderColor,
      radius: DashboardRadii.card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: insight.badgeBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: insight.borderColor,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  insight.icon,
                  size: 18,
                  color: insight.badgeForeground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DashboardBadge(
                      label: insight.eyebrow,
                      backgroundColor: insight.badgeBackground,
                      foregroundColor: insight.badgeForeground,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      insight.title,
                      style: type.rowTitle.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.body,
            style: type.body.copyWith(
              color: DashboardShellPalette.softInk,
              height: 1.36,
            ),
          ),
          if (insight.detail != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              insight.detail!,
              style: type.supporting.copyWith(
                color: DashboardShellPalette.mutedInk,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey<String>('product-guidance-open-trust-sheet'),
              onPressed: onOpenTrustSheet,
              child: const Text('Why this view'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeInsightState {
  const _HomeInsightState({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.body,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.borderColor,
    this.detail,
  });

  factory _HomeInsightState.fromSnapshot(
    RuntimeDashboardSnapshot snapshot, {
    required RuntimeLocalMessageSourceStatus sourceStatus,
    required DashboardTotalsSummaryPresentation totalsSummary,
  }) {
    final reviewCount = snapshot.reviewQueue.length;
    final includedCount = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
        .length;
    final manualCount = snapshot.manualSubscriptions.length;

    if (sourceStatus.tone == RuntimeLocalMessageSourceTone.demo) {
      return const _HomeInsightState(
        eyebrow: 'Sample preview',
        icon: Icons.visibility_outlined,
        title: 'Home is showing example data for now.',
        body:
            'Run an on-device scan whenever you are ready, and this preview will be replaced by your own subscription reality.',
        detail:
            'SubWatch keeps paid subscriptions, Review, and included services separate on purpose.',
        badgeBackground: DashboardShellPalette.statusBlueSoft,
        badgeForeground: DashboardShellPalette.statusBlue,
        borderColor: DashboardShellPalette.outlineStrong,
      );
    }

    if (sourceStatus.tone == RuntimeLocalMessageSourceTone.caution) {
      return const _HomeInsightState(
        eyebrow: 'Access is off',
        icon: Icons.lock_outline_rounded,
        title: 'Your last safe view stayed in place.',
        body:
            'Home does not guess when SMS access is off. It keeps the current local view until you choose to refresh it.',
        detail: 'Nothing leaves this phone during a scan.',
        badgeBackground: DashboardShellPalette.cautionSoft,
        badgeForeground: DashboardShellPalette.caution,
        borderColor: DashboardShellPalette.outlineStrong,
      );
    }

    if (reviewCount > 0) {
      return _HomeInsightState(
        eyebrow: 'Review is separate',
        icon: Icons.rule_folder_outlined,
        title: reviewCount == 1
            ? '1 item is protecting this summary.'
            : '$reviewCount items are protecting this summary.',
        body:
            'SubWatch keeps unclear recurring signals out of confirmed subscriptions until the billing proof is strong enough.',
        detail:
            'That keeps Home careful instead of overstating what you definitely pay for.',
        badgeBackground: DashboardShellPalette.cautionSoft,
        badgeForeground: DashboardShellPalette.caution,
        borderColor: DashboardShellPalette.outlineStrong,
      );
    }

    if (includedCount > 0) {
      return _HomeInsightState(
        eyebrow: 'Included access',
        icon: Icons.workspace_premium_outlined,
        title: includedCount == 1
            ? '1 included service stayed separate.'
            : '$includedCount included services stayed separate.',
        body:
            'Bundled access and benefits remain visible without being counted as paid subscriptions.',
        detail:
            'That keeps Home grounded in direct recurring billing, not bundled perks.',
        badgeBackground: DashboardShellPalette.benefitGoldSoft,
        badgeForeground: DashboardShellPalette.benefitGold,
        borderColor: DashboardShellPalette.outlineStrong,
      );
    }

    if (manualCount > 0) {
      return _HomeInsightState(
        eyebrow: 'Manual entries',
        icon: Icons.edit_note_rounded,
        title: manualCount == 1
            ? '1 manual subscription is part of your local view.'
            : '$manualCount manual subscriptions are part of your local view.',
        body:
            'Entries you add yourself stay on this phone and can fill gaps without rewriting what the scan detected.',
        detail:
            'That gives you control while keeping the detected view honest.',
        badgeBackground: DashboardShellPalette.nestedPaper,
        badgeForeground: DashboardShellPalette.softInk,
        borderColor: DashboardShellPalette.outline,
      );
    }

    return _HomeInsightState(
      eyebrow: 'Trust note',
      icon: Icons.verified_outlined,
      title: totalsSummary.hasEstimatedSpend
          ? 'This total stays intentionally conservative.'
          : 'Home stays intentionally conservative.',
      body: totalsSummary.summaryCopy,
      detail:
          'Only confirmed subscriptions with supportable evidence belong in Home.',
      badgeBackground: DashboardShellPalette.successSoft,
      badgeForeground: DashboardShellPalette.success,
      borderColor: DashboardShellPalette.outline,
    );
  }

  final String eyebrow;
  final IconData icon;
  final String title;
  final String body;
  final String? detail;
  final Color badgeBackground;
  final Color badgeForeground;
  final Color borderColor;
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
    final frequency =
        card.frequencyLabel ?? _fallbackFrequencyLabel(card.bucket);
    final amount = card.amountLabel ?? _fallbackAmountLabel(card.bucket);
    final combinedAmount = (frequency.isNotEmpty && amount.isNotEmpty)
        ? '$amount/${_shortFrequency(frequency)}'
        : amount;

    return _SubscriptionCardMetadata(
      amountLabel: combinedAmount,
      renewalLabel:
          renewal?.renewalDateLabel ?? _fallbackRenewalLabel(card.bucket),
      frequencyLabel: frequency,
      bundledSummary: card.bucket == DashboardBucket.trialsAndBenefits
          ? 'Included with your plan \u2014 no separate charge.'
          : null,
    );
  }

  static String _shortFrequency(String frequency) {
    final lowercase = frequency.toLowerCase();
    if (lowercase.contains('month')) return 'mo';
    if (lowercase.contains('year')) return 'yr';
    if (lowercase.contains('week')) return 'wk';
    if (lowercase.contains('day')) return 'day';
    return frequency;
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
    this.isBundled = false,
  });

  final Key amountValueKey;
  final String amountLabel;
  final Key renewalValueKey;
  final String renewalLabel;
  final Key? summaryValueKey;
  final String? bundledSummary;
  final bool isBundled;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    if (bundledSummary != null) {
      return Semantics(
        label: bundledSummary!,
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: DashboardShellPalette.nestedPaper.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isBundled
                        ? DashboardShellPalette.benefitGold
                        : DashboardShellPalette.outline)
                    .withValues(alpha: 0.26),
              ),
            ),
            child: Row(
              children: <Widget>[
                if (isBundled)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: DashboardShellPalette.benefitGold,
                    ),
                  ),
                Expanded(
                  child: Text(
                    bundledSummary!,
                    key: summaryValueKey,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.supporting.copyWith(
                      color: isBundled
                          ? DashboardShellPalette.benefitGold
                          : DashboardShellPalette.softInk,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                    ),
                  ),
                ),
              ],
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
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              amountLabel,
              key: amountValueKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.rowTitle.copyWith(
                color: DashboardShellPalette.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: DashboardShellPalette.nestedPaper.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: DashboardShellPalette.outline.withValues(alpha: 0.82),
                ),
              ),
              child: Text(
                _subscriptionCardDueLabel(renewalLabel),
                key: renewalValueKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.meta.copyWith(
                  color: DashboardShellPalette.softInk,
                ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.08),
          DashboardShellPalette.nestedPaper,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
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
    final type = context.dashboardType;
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
    final showsBucketBadge = card.bucket == DashboardBucket.needsReview ||
        card.bucket == DashboardBucket.hidden;
    final supportingLine = displayTitle != card.subtitle &&
            card.subtitle.isNotEmpty &&
            !_isFrequencyOnly(card.subtitle)
        ? card.subtitle
        : null;

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
                  borderRadius: BorderRadius.circular(20),
                  splashColor: style.badgeForeground.withValues(alpha: 0.08),
                  highlightColor: style.badgeForeground.withValues(alpha: 0.04),
                  hoverColor: style.badgeForeground.withValues(alpha: 0.03),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
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
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Builder(
                                builder: (context) {
                                  final stackedTitle =
                                      MediaQuery.sizeOf(context).width < 380 ||
                                              MediaQuery.textScalerOf(context)
                                                  .scale(1) >
                                              1.15;
                                  final title = Text(
                                    displayTitle,
                                    style: type.rowTitle.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  );
                                  final badge = showsBucketBadge
                                      ? DashboardBadge(
                                          label: style.badgeLabel,
                                          backgroundColor: style.badgeBackground,
                                          foregroundColor:
                                              style.badgeForeground,
                                        )
                                      : null;

                                  if (stackedTitle && badge != null) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        title,
                                        const SizedBox(height: 5),
                                        badge,
                                      ],
                                    );
                                  }

                                  if (badge == null) {
                                    return title;
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(child: title),
                                      const SizedBox(width: 8),
                                      badge,
                                    ],
                                  );
                                },
                              ),
                              if (supportingLine != null) ...<Widget>[
                                const SizedBox(height: 5),
                                Text(
                                  supportingLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: type.supporting.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                  ),
                                ),
                              ],
                              if (servicePresentationState.isPinned ||
                                  servicePresentationState
                                      .hasLocalLabel) ...<Widget>[
                                const SizedBox(height: 9),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    if (servicePresentationState.isPinned)
                                      const _InlineCardStatus(
                                        icon: Icons.push_pin_rounded,
                                        label: 'Pinned',
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
                              ],
                              const SizedBox(height: 10),
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
                                isBundled: card.bucket ==
                                    DashboardBucket.trialsAndBenefits,
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
            padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
            child: trailing,
          ),
        ],
      ),
    );
  }
}

bool _isFrequencyOnly(String text) {
  final lowercase = text.toLowerCase();
  return lowercase == 'monthly' ||
      lowercase == 'yearly' ||
      lowercase == 'weekly' ||
      lowercase == 'daily' ||
      lowercase == 'fixed' ||
      lowercase == 'recurring';
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
          badgeLabel: 'Included',
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
                    label: const Text('Set reminder'),
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
        description:
            'SubWatch is still sorting paid, review, and benefit items.',
      );
    }
    if (elapsed >= const Duration(seconds: 2)) {
      return const _SyncProgressPresentation(
        title: 'Sorting confirmed, review, and benefit items',
        description:
            'SubWatch is separating strong paid signals from the rest.',
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
                    label: 'Included with your plan',
                    value: samplePreview!.trialCountLabel,
                    caption: 'Included service',
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
                      label: 'Included with your plan',
                      value: samplePreview!.trialCountLabel,
                      caption: 'Included service',
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
          title: 'Included with your plan',
          badgeLabel: _previewCountLabel(trialCards.length),
          description: trialTitles.isEmpty
              ? 'Bundled access stays visible without being counted as paid.'
              : '${trialTitles.first} stays visible as an included service.',
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
                  child: const Text('Add subscription'),
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
        ? 'You can review each item yourself, add a subscription, or wait for a later billing message to make the picture clearer.'
        : hasTrialCards
            ? 'Recharges, bundled access, and free benefits do not get counted as paid subscriptions. If you already know one you pay for directly, you can still add it yourself.'
            : 'One-time payments, mandate setup, recharges, and bundled access are kept out of confirmed subscriptions on purpose. If you already know one you pay for, you can still add it yourself.';

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
        title: 'Included with your plan',
        count: trialCards.length,
        description: trialCards.isEmpty
            ? 'No bundled or trial access stood out in this scan.'
            : _summarizeFindingTitles(
                trialCards.map((card) => card.title),
                singularLabel: 'included service found',
                pluralLabel: 'included services found',
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
        return 'Add subscription';
    }
  }

  String? get actionHint {
    if (manualCount > 0) {
      return manualCount == 1
          ? '1 subscription you added already stays separate in your subscriptions list.'
          : '$manualCount subscriptions you added already stay separate in your subscriptions list.';
    }
    if (primaryActionKind == _ZeroConfirmedPrimaryActionKind.manualAdd) {
      return 'If you already know one you pay for, you can add it yourself without changing this scan result.';
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

class _FirstRunSurface extends StatelessWidget {
  const _FirstRunSurface({
    required this.shell,
    required this.phase,
    this.firstScanSnapshot,
  });

  final _DashboardShellState shell;
  final FirstRunPhase phase;
  final RuntimeDashboardSnapshot? firstScanSnapshot;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration:
          shouldReduceMotion(context) ? Duration.zero : dashboardMotionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: switch (phase) {
        FirstRunPhase.loading => const _DashboardLoadingState(),
        FirstRunPhase.gate => _FirstRunGateState(
            key: const ValueKey<String>('first-run-gate'),
            onGetStarted: shell._handleFirstRunGetStarted,
          ),
        FirstRunPhase.denied => _FirstRunDeniedState(
            key: const ValueKey<String>('first-run-denied'),
            onTryAgain: shell._handleFirstRunRetry,
            onNotNow: shell._handleFirstRunNotNow,
          ),
        FirstRunPhase.permanentlyDenied => _FirstRunPermanentlyDeniedState(
            key: const ValueKey<String>('first-run-permanently-denied'),
            onOpenSettings: shell._handleFirstRunOpenSettings,
            onNotNow: shell._handleFirstRunNotNow,
          ),
        FirstRunPhase.scanning => const _FirstRunScanningState(
            key: ValueKey<String>('first-run-scanning'),
          ),
        FirstRunPhase.firstResult => _FirstRunZeroResultState(
            key: const ValueKey<String>('first-run-zero-result'),
            snapshot: firstScanSnapshot,
            onDone: shell._handleFirstRunDone,
          ),
        FirstRunPhase.completed => const SizedBox.shrink(),
      },
    );
  }
}

class _FirstRunGateState extends StatelessWidget {
  const _FirstRunGateState({
    super.key,
    required this.onGetStarted,
  });

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.94, end: 1),
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
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
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: DashboardShellPalette.elevatedPaper,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: DashboardShellPalette.outlineStrong,
                  ),
                ),
                alignment: Alignment.center,
                child: const SubWatchBrandMark(size: 56, showBase: true),
              ),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                child: Text(
                  'Find subscriptions\nhiding in your SMS',
                  key: const ValueKey<String>('first-run-gate-headline'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.smartphone_rounded,
                    size: 16,
                    color: DashboardShellPalette.mutedInk,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your messages are checked on-device',
                      key: const ValueKey<String>('first-run-gate-trust'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                            height: 1.3,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label:
                      'Get started \u2014 scan your SMS messages for subscriptions',
                  child: FilledButton(
                    key: const ValueKey<String>('first-run-get-started-button'),
                    onPressed: onGetStarted,
                    child: const Text('Get started'),
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

class _FirstRunDeniedState extends StatelessWidget {
  const _FirstRunDeniedState({
    super.key,
    required this.onTryAgain,
    required this.onNotNow,
  });

  final VoidCallback onTryAgain;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DashboardShellPalette.cautionSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: DashboardShellPalette.outline,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.sms_outlined,
                size: 32,
                color: DashboardShellPalette.caution,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SubWatch needs SMS access to find your subscriptions.',
              key: const ValueKey<String>('first-run-denied-message'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: 'Try again to grant SMS access',
                child: FilledButton(
                  key: const ValueKey<String>('first-run-try-again-button'),
                  onPressed: onTryAgain,
                  child: const Text('Try again'),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const ValueKey<String>('first-run-not-now-button'),
                onPressed: onNotNow,
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstRunPermanentlyDeniedState extends StatelessWidget {
  const _FirstRunPermanentlyDeniedState({
    super.key,
    required this.onOpenSettings,
    required this.onNotNow,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DashboardShellPalette.cautionSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: DashboardShellPalette.outline,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.settings_outlined,
                size: 32,
                color: DashboardShellPalette.caution,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SMS access is off. Turn it on in Settings to scan your messages.',
              key: const ValueKey<String>(
                  'first-run-permanently-denied-message'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: 'Open device settings to enable SMS access',
                child: FilledButton.icon(
                  key: const ValueKey<String>('first-run-open-settings-button'),
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Settings'),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const ValueKey<String>(
                    'first-run-perm-denied-not-now-button'),
                onPressed: onNotNow,
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstRunScanningState extends StatefulWidget {
  const _FirstRunScanningState({super.key});

  @override
  State<_FirstRunScanningState> createState() => _FirstRunScanningStateState();
}

class _FirstRunScanningStateState extends State<_FirstRunScanningState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (shouldReduceMotion(context)) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final glow = reduceMotion ? 0.0 : _pulseController.value;
                return Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: DashboardShellPalette.elevatedPaper,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Color.lerp(
                        DashboardShellPalette.outlineStrong,
                        DashboardShellPalette.accent,
                        glow * 0.5,
                      )!,
                    ),
                    boxShadow: reduceMotion
                        ? null
                        : <BoxShadow>[
                            BoxShadow(
                              color: DashboardShellPalette.accent
                                  .withValues(alpha: 0.12 * glow),
                              blurRadius: 24 * glow,
                              spreadRadius: 2 * glow,
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: const SubWatchBrandMark(size: 48, showBase: true),
                );
              },
            ),
            const SizedBox(height: 24),
            Semantics(
              liveRegion: true,
              child: Text(
                'Checking messages\u2026',
                key: const ValueKey<String>('first-run-scanning-headline'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looking for paid subscriptions and bundled access',
              key: const ValueKey<String>('first-run-scanning-support'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.3,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstRunZeroResultState extends StatelessWidget {
  const _FirstRunZeroResultState({
    super.key,
    required this.snapshot,
    required this.onDone,
  });

  final RuntimeDashboardSnapshot? snapshot;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.96, end: 1),
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DashboardShellPalette.successSoft,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: DashboardShellPalette.outline,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 36,
                  color: DashboardShellPalette.success,
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  'No paid subscriptions confirmed yet',
                  key: const ValueKey<String>('first-run-zero-result-headline'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Included services and uncertain items stay separate',
                key: const ValueKey<String>('first-run-zero-result-support'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      height: 1.3,
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'Continue to SubWatch home',
                  child: FilledButton(
                    key: const ValueKey<String>('first-run-done-button'),
                    onPressed: onDone,
                    child: const Text('Check again'),
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
              'Your messages are checked on this phone. Paid subscriptions stay separate from Review and included services.',
          primaryActionLabel: 'Start with SMS permission',
          secondaryActionLabel: 'Browse sample first',
        );

      case RuntimeLocalMessageSourcePermissionRationaleVariant.retry:
        return const _SmsPermissionRationaleContent(
          title: 'SMS access is off',
          description:
              'Turn SMS access back on to scan this phone again. Your messages are checked on-device.',
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

class _ReviewDecisionDeskHeader extends StatelessWidget {
  const _ReviewDecisionDeskHeader({
    required this.reviewCount,
  });

  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final countLabel = reviewCount == 1 ? '1 item' : '$reviewCount items';
    final isEmpty = reviewCount == 0;

    return DashboardPanel(
      key: const ValueKey<String>('review-decision-desk-header'),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          isEmpty ? const Color(0xFF1A1613) : const Color(0xFF241B16),
          DashboardShellPalette.paper,
        ],
      ),
      borderColor: isEmpty
          ? DashboardShellPalette.outlineStrong
          : DashboardShellPalette.outline,
      radius: DashboardRadii.prominentCard,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              DashboardBadge(
                label: isEmpty ? 'Clear for now' : '$countLabel waiting',
                icon: isEmpty
                    ? Icons.verified_outlined
                    : Icons.shield_moon_outlined,
                backgroundColor: isEmpty
                    ? DashboardShellPalette.successSoft
                    : DashboardShellPalette.nestedPaper,
                foregroundColor: isEmpty
                    ? DashboardShellPalette.success
                    : DashboardShellPalette.softInk,
              ),
              const DashboardBadge(
                label: 'Careful review',
                icon: Icons.lock_outline_rounded,
                backgroundColor: DashboardShellPalette.registerPaper,
                foregroundColor: DashboardShellPalette.mutedInk,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty
                ? 'Review is clear for now'
                : 'Review keeps uncertain items separate',
            style: type.screenTitle.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEmpty
                ? 'SubWatch only uses this space when something needs a closer look.'
                : 'These items stay out of your confirmed subscriptions until you decide or the signal becomes clearer.',
            style: type.supporting.copyWith(
              color: DashboardShellPalette.softInk,
              height: 1.34,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDeskEmptyState extends StatelessWidget {
  const _ReviewDeskEmptyState();

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    return DashboardPanel(
      key: const ValueKey<String>('review-desk-empty-state'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DashboardShellPalette.successSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DashboardShellPalette.success.withValues(alpha: 0.18),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_outlined,
              color: DashboardShellPalette.success,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Nothing to review right now',
            style: type.sectionTitle.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your confirmed list stays conservative, and nothing currently needs a closer look.',
            style: type.supporting.copyWith(
              color: DashboardShellPalette.mutedInk,
              height: 1.32,
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
    super.caption,
    required super.children,
  });
}

class _HowSubWatchWorksSheet extends StatelessWidget {
  const _HowSubWatchWorksSheet();

  @override
  Widget build(BuildContext context) {
    return _SettingsDetailSheet(
      sheetKey: const ValueKey<String>('how-subwatch-works-sheet'),
      title: 'How SubWatch works',
      subtitle: 'How SubWatch decides what belongs here.',
      children: const <Widget>[
        _TrustSheetSection(
          title: 'Paid subscriptions',
          items: <String>[
            'Paid subscriptions need clear recurring billing proof.',
            'One-time payments, setup messages, and Rs 1 or Rs 2 checks are not enough.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'Review',
          items: <String>[
            'Review holds items that still need your decision.',
            'Weak recurring-looking signals stay there until the evidence is clearer.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'Included with your plan',
          items: <String>[
            'Bundles, trials, and free access stay separate from paid subscriptions.',
            'Keeping them separate helps avoid false positives.',
          ],
        ),
      ],
    );
  }
}

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet();

  @override
  Widget build(BuildContext context) {
    return _SettingsDetailSheet(
      sheetKey: const ValueKey<String>('privacy-sheet'),
      title: 'Privacy',
      subtitle: 'What stays on this phone.',
      children: const <Widget>[
        _TrustSheetSection(
          title: 'Private on this phone',
          items: <String>[
            'Your messages are checked on-device.',
            'No cloud account is needed to use SubWatch.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'What stays here',
          items: <String>[
            'Subscription summaries, reminders, and your decisions stay on this phone.',
            'A scan refreshes this phone view with the latest results.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'What SubWatch does not do',
          items: <String>[
            'It does not upload your SMS inbox.',
            'It does not run passive background monitoring.',
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
          title: 'What it is',
          items: <String>[
            'SubWatch helps you spot subscriptions from your messages.',
            'It keeps subscriptions, Review, and included services separate.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'What it is not',
          items: <String>[
            'It is not a payments inbox.',
            'It is not a cloud account or budget tracker.',
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
    super.subtitle,
    super.onTap,
    super.trailing,
    super.tone,
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

class _SettingsTrustPanel extends DashboardSettingsTrustPanel {
  const _SettingsTrustPanel({
    super.key,
    required super.title,
    super.subtitle,
  });
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

class _SubscriptionsBrowseHeader extends StatelessWidget {
  const _SubscriptionsBrowseHeader({
    required this.visibleCount,
    required this.controls,
    required this.hasManualEntries,
  });

  final int visibleCount;
  final DashboardServiceViewControls controls;
  final bool hasManualEntries;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    return DashboardPanel(
      key: const ValueKey<String>('subscriptions-browse-header'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outline,
      radius: DashboardRadii.card,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DashboardBadge(
            label: _eyebrow(),
            backgroundColor: DashboardShellPalette.nestedPaper,
            foregroundColor: DashboardShellPalette.softInk,
          ),
          const SizedBox(height: 12),
          Text(
            visibleCount == 0
                ? 'Nothing is standing in this view yet.'
                : visibleCount == 1
                    ? '1 subscription truth is visible.'
                    : '$visibleCount subscription truths are visible.',
            style: type.sectionTitle.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _supportCopy(),
            style: type.supporting.copyWith(
              color: DashboardShellPalette.mutedInk,
              height: 1.32,
            ),
          ),
        ],
      ),
    );
  }

  String _eyebrow() {
    if (controls.isSearchActive) {
      return 'Search active';
    }
    if (controls.isFilterActive) {
      return 'Filtered view';
    }
    if (controls.sortMode != DashboardServiceSortMode.currentOrder) {
      return 'Sorted view';
    }
    return 'Truth list';
  }

  String _supportCopy() {
    if (controls.isSearchActive && controls.isFilterActive) {
      return 'Search and filters are narrowing the list without changing the underlying subscription view.';
    }
    if (controls.isSearchActive) {
      return 'Search is narrowing the list by visible service names and your local labels only.';
    }
    if (controls.isFilterActive) {
      return 'Filters are narrowing the list without changing what SubWatch actually detected.';
    }
    if (hasManualEntries) {
      return 'Detected subscriptions and the subscriptions you added yourself stay clearly separated here.';
    }
    return 'This list stays focused on subscription realities SubWatch is willing to stand behind.';
  }
}

class _ServiceViewControlsPanel extends StatelessWidget {
  const _ServiceViewControlsPanel({
    required this.searchController,
    required this.controls,
    required this.availableFilterModes,
    required this.onSortChanged,
    required this.onFilterChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final DashboardServiceViewControls controls;
  final List<DashboardServiceFilterMode> availableFilterModes;
  final ValueChanged<DashboardServiceSortMode> onSortChanged;
  final ValueChanged<DashboardServiceFilterMode> onFilterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final stacked = MediaQuery.sizeOf(context).width < 420 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;
    final actionButtons = <Widget>[
      _ServiceViewMenuButton<DashboardServiceSortMode>(
        menuKey: const ValueKey<String>('service-sort-menu'),
        tooltip: 'Sort subscriptions',
        semanticLabel: 'Sort subscriptions',
        icon: Icons.swap_vert_rounded,
        label: _sortButtonLabel(),
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
        label: _filterButtonLabel(),
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
      if (controls.hasActiveControls)
        _ServiceViewIconButton(
          key: const ValueKey<String>('reset-service-view-controls'),
          tooltip: 'Reset view',
          semanticLabel: 'Reset subscriptions view',
          icon: Icons.refresh_rounded,
          label: 'Reset',
          onPressed: onClear,
        ),
    ];

    return DashboardPanel(
      key: const ValueKey<String>('service-view-controls-panel'),
      backgroundColor: DashboardShellPalette.elevatedPaper,
      borderColor: DashboardShellPalette.outline,
      radius: DashboardRadii.card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Browse tools',
            style: type.meta.copyWith(
              color: DashboardShellPalette.faintInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 12),
          if (stacked)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actionButtons,
            )
          else
            Row(
              children: <Widget>[
                ...actionButtons.expand((widget) => <Widget>[
                      widget,
                      const SizedBox(width: 8),
                    ]),
              ]..removeLast(),
            ),
        ],
      ),
    );
  }

  String _sortButtonLabel() {
    switch (controls.sortMode) {
      case DashboardServiceSortMode.currentOrder:
        return 'Default';
      case DashboardServiceSortMode.nameAscending:
        return 'Name A-Z';
      case DashboardServiceSortMode.nameDescending:
        return 'Name Z-A';
    }
  }

  String _filterButtonLabel() {
    switch (controls.filterMode) {
      case DashboardServiceFilterMode.allVisible:
        return 'All';
      case DashboardServiceFilterMode.confirmedOnly:
        return 'Subscriptions';
      case DashboardServiceFilterMode.observedOnly:
        return 'Needs review';
      case DashboardServiceFilterMode.separateAccessOnly:
        return 'Included';
    }
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
        return 'Included with your plan';
    }
  }
}

class _ServiceViewMenuButton<T> extends StatelessWidget {
  const _ServiceViewMenuButton({
    required this.menuKey,
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.label,
    required this.active,
    required this.itemBuilder,
    required this.onSelected,
  });

  final Key menuKey;
  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final String label;
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
        label: label,
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
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final String label;
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
            label: label,
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
    required this.label,
    this.active = false,
  });

  final String semanticLabel;
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final foregroundColor = active
        ? DashboardShellPalette.accent
        : DashboardShellPalette.softInk;
    final backgroundColor = active
        ? DashboardShellPalette.accentSoft
        : DashboardShellPalette.nestedPaper;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 88),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? DashboardShellPalette.accent.withValues(alpha: 0.34)
                : DashboardShellPalette.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: foregroundColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: type.meta.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedSubscriptionSection extends StatefulWidget {
  const _CollapsedSubscriptionSection({
    required this.sectionKey,
    required this.label,
    required this.icon,
    required this.countLabel,
    required this.caption,
    required this.children,
  });

  final String sectionKey;
  final String label;
  final IconData icon;
  final String countLabel;
  final String caption;
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
    final type = context.dashboardType;
    return DashboardPanel(
      key: ValueKey<String>('toggle-section-${widget.sectionKey}'),
      backgroundColor: DashboardShellPalette.nestedPaper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: DashboardShellPalette.registerPaper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DashboardShellPalette.benefitGold
                          .withValues(alpha: 0.16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: DashboardShellPalette.benefitGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.label,
                              style: type.rowTitle.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: DashboardShellPalette.paper,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: DashboardShellPalette.outline,
                              ),
                            ),
                            child: Text(
                              widget.countLabel,
                              style: type.meta.copyWith(
                                color: DashboardShellPalette.softInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.caption,
                        style: type.supporting.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          height: 1.24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
    return DashboardPanel(
      key: const ValueKey<String>('service-view-empty-state'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _EmptySectionText(
            title: 'Nothing matches this view',
            message:
                'Try another search or reset the filters. If something is still missing, you can add it yourself.',
            icon: Icons.search_off_rounded,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            key: const ValueKey<String>('reset-service-view-controls-empty'),
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset filters'),
          ),
        ],
      ),
    );
  }
}

class _ManualLedgerNote extends StatelessWidget {
  const _ManualLedgerNote({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: DashboardShellPalette.registerPaper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: DashboardShellPalette.statusBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardShellPalette.statusBlue,
              fontWeight: FontWeight.w700,
            ),
      ),
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

class _SettingsReminderManagerSheet extends StatelessWidget {
  const _SettingsReminderManagerSheet({
    required this.reminderItems,
    required this.busyTargets,
    required this.onOpenReminderControls,
  });

  final List<DashboardRenewalReminderItemPresentation> reminderItems;
  final Set<String> busyTargets;
  final ValueChanged<DashboardRenewalReminderItemPresentation>
      onOpenReminderControls;

  @override
  Widget build(BuildContext context) {
    final activeCount =
        reminderItems.where((item) => item.selectedPreset != null).length;
    final type = context.dashboardType;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('settings-reminder-manager-sheet'),
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
                const DashboardBadge(
                  label: 'Trust details',
                  icon: Icons.notifications_none_rounded,
                  backgroundColor: DashboardShellPalette.nestedPaper,
                  foregroundColor: DashboardShellPalette.softInk,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Renewal reminders',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeCount == 1
                                ? '1 reminder is active on this phone.'
                                : activeCount > 1
                                    ? '$activeCount reminders are active on this phone.'
                                    : 'Reminders stay on this phone.',
                            style: type.supporting.copyWith(
                              color: DashboardShellPalette.mutedInk,
                              height: 1.28,
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
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.paper,
                  borderColor: DashboardShellPalette.outlineStrong,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Reminder controls',
                        style: type.rowTitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Each reminder stays local to this phone and follows the renewal date already visible in SubWatch.',
                        style: type.supporting.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          height: 1.26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (var index = 0;
                          index < reminderItems.length;
                          index++) ...<Widget>[
                        _SettingsNavRow(
                          tileKey: ValueKey<String>(
                            'settings-reminder-item-${reminderItems[index].renewal.serviceKey}',
                          ),
                          icon: Icons.notifications_none_rounded,
                          title: reminderItems[index].renewal.serviceTitle,
                          subtitle:
                              '${reminderItems[index].renewal.renewalDateLabel} - ${reminderItems[index].statusLabel}',
                          onTap: busyTargets.contains(
                            reminderItems[index].renewal.serviceKey,
                          )
                              ? null
                              : () => onOpenReminderControls(
                                    reminderItems[index],
                                  ),
                          trailing: busyTargets.contains(
                            reminderItems[index].renewal.serviceKey,
                          )
                              ? Text(
                                  'Working...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: DashboardShellPalette.mutedInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                )
                              : null,
                        ),
                        if (index != reminderItems.length - 1)
                          const _SettingsGroupDivider(),
                      ],
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
                        'Renewal reminder',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stays on this phone and only appears for clear renewal dates.',
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
                              'Renewal reminder',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stays on this phone and only appears for clear renewal dates.',
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
    final type = context.dashboardType;
    final supportingLine = entry.hasPlanLabel
        ? entry.planLabel!
        : (entry.billingCycle == ManualSubscriptionBillingCycle.monthly
            ? 'Monthly plan'
            : 'Yearly plan');

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
              hint: 'Opens subscription details',
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  splashColor:
                      DashboardShellPalette.statusBlue.withValues(alpha: 0.08),
                  highlightColor:
                      DashboardShellPalette.statusBlue.withValues(alpha: 0.04),
                  hoverColor:
                      DashboardShellPalette.statusBlue.withValues(alpha: 0.03),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DashboardServiceAvatar(
                          monogram: identity.monogram,
                          foregroundColor: identity.foreground,
                          backgroundColor: identity.background,
                          borderColor: identity.border,
                          sealColor: DashboardShellPalette.statusBlue,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.serviceName,
                                style: type.rowTitle.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                supportingLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: type.supporting.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  const _ManualLedgerNote(label: 'Added by you'),
                                  if (entry.hasNextRenewalDate)
                                    const _InlineCardStatus(
                                      icon: Icons.event_available_outlined,
                                      label: 'Renewal tracked',
                                      color: DashboardShellPalette.statusBlue,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
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
            padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
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
                      child: Text('Set reminder'),
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
                      label:
                          'Edit subscription you added for ${entry.serviceName}',
                      child: FilledButton(
                        key: ValueKey<String>(
                            'edit-manual-subscription-${entry.id}'),
                        onPressed: onEdit,
                        child: const Text('Edit details'),
                      ),
                    ),
                    _ContextualActionSemantics(
                      label:
                          'Remove subscription you added for ${entry.serviceName}',
                      child: TextButton(
                        key: ValueKey<String>(
                            'delete-manual-subscription-${entry.id}'),
                        onPressed: onDelete,
                        child: const Text('Remove from list'),
                      ),
                    ),
                    if (onOpenReminderControls != null)
                      _ContextualActionSemantics(
                        label: 'Set a reminder for ${entry.serviceName}',
                        child: TextButton.icon(
                          key: ValueKey<String>(
                              'open-reminder-manual-subscription-${entry.id}'),
                          onPressed: onOpenReminderControls,
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                          ),
                          label: const Text('Set reminder'),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: DashboardShellPalette.mutedInk),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: DashboardShellPalette.mutedInk),
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
        hoverColor: (brandEntry?.brandColor ?? DashboardShellPalette.statusBlue)
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
                            ? 'Edit added subscription'
                            : 'Add a subscription',
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
                                  ? 'Edit added subscription'
                                  : 'Add a subscription',
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
    required this.isBusy,
    required this.onOpenDetails,
    required this.onConfirm,
    required this.onMarkAsBenefit,
    required this.onEditDetails,
    required this.onDismiss,
  });

  final ReviewItem item;
  final ReviewItemActionDescriptor descriptor;
  final ReviewQueueItemPresentation presentation;
  final bool isBusy;
  final VoidCallback onOpenDetails;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkAsBenefit;
  final VoidCallback? onEditDetails;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      debugPrint(
          'ReviewDecisionPassportCard: isBusy=true for ${descriptor.targetKey}');
    }
    final type = context.dashboardType;
    final identity = _identityStyle(
      item.title,
      accentColor: DashboardShellPalette.statusBlue,
    );
    final summary = _reviewCardSemantics(
      item,
      presentation: presentation,
      descriptor: descriptor,
    );
    final titleStyle = type.rowTitle.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 18,
    );
    final reasonStyle = type.supporting.copyWith(
      color: DashboardShellPalette.mutedInk,
      height: 1.28,
    );
    final filledActionStyle = FilledButton.styleFrom(
      minimumSize: const Size(136, 46),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
    final outlinedActionStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(126, 46),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
    final quietActionStyle = TextButton.styleFrom(
      minimumSize: const Size(112, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      foregroundColor: DashboardShellPalette.mutedInk,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
    final stateLabel = descriptor.canConfirm
        ? 'Needs your decision'
        : 'Needs a manual check';
    final actionTitle =
        descriptor.canConfirm ? 'Choose the safest match' : 'Finish this item';
    final actionHelper = descriptor.canConfirm
        ? 'Only confirmed subscriptions move into your list. If it is included access, keep it separate.'
        : 'Add it yourself if you recognize it, or mark it as not yours.';

    return Semantics(
      container: true,
      label: summary,
      child: DashboardPanel(
        backgroundColor: DashboardShellPalette.paper,
        borderColor: DashboardShellPalette.outlineStrong,
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                DashboardBadge(
                  label: stateLabel,
                  icon: descriptor.canConfirm
                      ? Icons.shield_moon_outlined
                      : Icons.edit_note_rounded,
                  backgroundColor: DashboardShellPalette.nestedPaper,
                  foregroundColor: DashboardShellPalette.softInk,
                ),
                if (isBusy) ...<Widget>[
                  const SizedBox(width: 8),
                  const DashboardBadge(
                    label: 'Saving',
                    icon: Icons.more_horiz_rounded,
                    backgroundColor: DashboardShellPalette.registerPaper,
                    foregroundColor: DashboardShellPalette.accent,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
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
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.reasonLine,
                        maxLines: 2,
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
              ],
            ),
            const SizedBox(height: 14),
            _ReviewDecisionActionsBlock(
              framed: true,
              title: actionTitle,
              helper: actionHelper,
              accentColor: DashboardShellPalette.statusBlue,
              children: <Widget>[
                if (descriptor.canConfirm)
                  _ContextualActionSemantics(
                    label: 'Confirm ${item.title} as a paid subscription',
                    enabled: !isBusy,
                    child: FilledButton.icon(
                      key: ValueKey<String>(
                        'confirm-review-action-${descriptor.targetKey}',
                      ),
                      style: filledActionStyle,
                      onPressed: isBusy ? null : onConfirm,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: Text(
                        isBusy ? 'Working...' : presentation.confirmLabel!,
                      ),
                    ),
                  ),
                if (descriptor.canConfirm)
                  _ContextualActionSemantics(
                    label: 'Keep ${item.title} separate as a benefit or bundle',
                    enabled: !isBusy,
                    child: OutlinedButton.icon(
                      key: ValueKey<String>(
                        'benefit-review-action-${descriptor.targetKey}',
                      ),
                      style: outlinedActionStyle,
                      onPressed: isBusy ? null : onMarkAsBenefit,
                      icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                      label: Text(
                        isBusy ? 'Working...' : presentation.benefitLabel!,
                      ),
                    ),
                  ),
                if (!descriptor.canConfirm)
                  _ContextualActionSemantics(
                    label: 'Add ${item.title} as a subscription',
                    enabled: !isBusy,
                    child: FilledButton.icon(
                      key: ValueKey<String>(
                        'edit-review-action-${descriptor.targetKey}',
                      ),
                      style: filledActionStyle,
                      onPressed: isBusy ? null : onEditDetails,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: Text(
                        isBusy ? 'Working...' : presentation.editLabel,
                      ),
                    ),
                  ),
                _ContextualActionSemantics(
                  label: 'Mark ${item.title} as not a subscription',
                  enabled: !isBusy,
                  child: TextButton.icon(
                    key: ValueKey<String>(
                      'dismiss-review-action-${descriptor.targetKey}',
                    ),
                    style: quietActionStyle,
                    onPressed: isBusy ? null : onDismiss,
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                    label: Text(
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
    debugPrint(
        'ReviewDetailsButton: build targetKey=$targetKey isBusy=$isBusy onPressed=${onPressed}');
    return Semantics(
      button: true,
      label: 'Why SubWatch flagged $title',
      child: Tooltip(
        message: 'Why this?',
        child: TextButton(
          key: ValueKey<String>('open-review-details-$targetKey'),
          onPressed: isBusy ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: DashboardShellPalette.mutedInk,
            backgroundColor: DashboardShellPalette.nestedPaper,
            minimumSize: const Size(88, 42),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:
                  const BorderSide(color: DashboardShellPalette.outlineStrong),
            ),
          ),
          child: const Text('Why this?'),
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
    required this.isBusy,
    required this.onDismiss,
    required this.onIgnore,
    required this.onEditDetails,
    this.onConfirm,
    this.onMarkAsBenefit,
  });

  final ReviewItem item;
  final ReviewItemActionDescriptor descriptor;
  final ReviewQueueItemPresentation presentation;
  final bool isBusy;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkAsBenefit;
  final VoidCallback onDismiss;
  final VoidCallback onIgnore;
  final VoidCallback onEditDetails;

  @override
  Widget build(BuildContext context) {
    final accentColor = DashboardShellPalette.statusBlue;
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.reasonLine,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              presentation.reasonLine,
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
                  framed: true,
                  title: onConfirm != null
                      ? 'Choose the safest match'
                      : 'Finish this item',
                  helper: onConfirm != null
                      ? 'Review keeps this separate until you pick the best fit.'
                      : 'Add it yourself if you recognize it, or mark it as not yours.',
                  accentColor: accentColor,
                  children: <Widget>[
                    if (onConfirm != null)
                      _ContextualActionSemantics(
                        label: 'Confirm ${item.title} as a paid subscription',
                        enabled: !isBusy,
                        child: FilledButton.icon(
                          key: ValueKey<String>(
                            'review-details-confirm-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onConfirm,
                          icon:
                              const Icon(Icons.verified_outlined, size: 18),
                          label: Text(
                            isBusy ? 'Working...' : presentation.confirmLabel!,
                          ),
                        ),
                      ),
                    if (onMarkAsBenefit != null)
                      _ContextualActionSemantics(
                        label:
                            'Keep ${item.title} separate as a benefit or bundle',
                        enabled: !isBusy,
                        child: OutlinedButton.icon(
                          key: ValueKey<String>(
                            'review-details-benefit-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onMarkAsBenefit,
                          icon: const Icon(
                            Icons.workspace_premium_outlined,
                            size: 18,
                          ),
                          label: Text(
                            isBusy ? 'Working...' : presentation.benefitLabel!,
                          ),
                        ),
                      ),
                    if (onConfirm == null)
                      _ContextualActionSemantics(
                        label: 'Add ${item.title} as a subscription',
                        enabled: !isBusy,
                        child: FilledButton.icon(
                          key: ValueKey<String>(
                            'review-details-edit-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onEditDetails,
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: Text(
                            isBusy ? 'Working...' : presentation.editLabel,
                          ),
                        ),
                      ),
                    _ContextualActionSemantics(
                      label: 'Mark ${item.title} as not a subscription',
                      enabled: !isBusy,
                      child: TextButton.icon(
                        key: ValueKey<String>(
                          'review-details-dismiss-${descriptor.targetKey}',
                        ),
                        onPressed: isBusy ? null : onDismiss,
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isBusy ? 'Working...' : presentation.dismissLabel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ReviewEvidencePanel(
                  presentation: presentation,
                  accentColor: accentColor,
                  initiallyExpanded: true,
                ),
                const SizedBox(height: 10),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.nestedPaper,
                  borderColor: DashboardShellPalette.outlineStrong,
                  radius: 18,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Local control',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hide this item on this phone without changing review meaning.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                              height: 1.26,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: ValueKey<String>(
                            'ignore-review-item-action-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onIgnore,
                          icon: const Icon(
                            Icons.do_not_disturb_on_outlined,
                            size: 18,
                          ),
                          label: const Text('Hide on this phone'),
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
            children:
                children.expand((w) => [w, const SizedBox(height: 10)]).toList()
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
    this.initiallyExpanded = false,
  });

  final ReviewQueueItemPresentation presentation;
  final Color accentColor;
  final bool initiallyExpanded;

  @override
  State<_ReviewEvidencePanel> createState() => _ReviewEvidencePanelState();
}

class _ReviewEvidencePanelState extends State<_ReviewEvidencePanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      backgroundColor: DashboardShellPalette.nestedPaper,
      borderColor: DashboardShellPalette.outlineStrong,
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
              for (var index = 0;
                  index < widget.presentation.detailsBullets.length;
                  index++) ...<Widget>[
                _ReviewEvidenceBullet(
                  body: widget.presentation.detailsBullets[index],
                  accentColor: widget.accentColor,
                ),
                if (index < widget.presentation.detailsBullets.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewEvidenceBullet extends StatelessWidget {
  const _ReviewEvidenceBullet({
    required this.body,
    required this.accentColor,
  });

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
          child: Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  height: 1.3,
                ),
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

  final diffDays = now.difference(value).inDays;
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  final timeLabel = '$hour:$minute $period';

  if (sameDay) {
    return 'Today, $timeLabel';
  }
  if (isYesterday) {
    return 'Yesterday, $timeLabel';
  }
  if (diffDays > 1 && diffDays < 7) {
    return '$diffDays days ago';
  }
  return '${_formatManualDate(value)}, $timeLabel';
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

String _manualSubscriptionRowSemantics(ManualSubscriptionEntry entry) {
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
}

String _reviewCardSemantics(
  ReviewItem item, {
  required ReviewQueueItemPresentation presentation,
  required ReviewItemActionDescriptor descriptor,
}) {
  final parts = <String>[
    item.title,
    presentation.reasonLine,
    descriptor.canConfirm
        ? 'Review actions below'
        : 'Add a subscription or mark as not yours',
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
