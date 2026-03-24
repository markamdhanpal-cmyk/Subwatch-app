import 'package:flutter/material.dart';

import '../dashboard_primitives.dart';
import 'dashboard_section_components.dart';

class DashboardSettingsGroupPanel extends StatelessWidget {
  const DashboardSettingsGroupPanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: type.subheading.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: type.caption.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  height: 1.28,
                ),
          ),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: DashboardShellPalette.paper.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DashboardShellPalette.outline.withValues(alpha: 0.55),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class DashboardSettingsSubsection extends StatelessWidget {
  const DashboardSettingsSubsection({
    super.key,
    required this.title,
    required this.caption,
    required this.children,
  });

  final String title;
  final String caption;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: type.subheading.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: type.caption.copyWith(
                color: DashboardShellPalette.mutedInk,
                height: 1.28,
              ),
        ),
        const SizedBox(height: 10),
        DashboardInsetListGroup(children: children),
      ],
    );
  }
}

class DashboardSettingsNavRow extends StatelessWidget {
  const DashboardSettingsNavRow({
    super.key,
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title. $subtitle.',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: tileKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor:
                DashboardShellPalette.statusBlue.withValues(alpha: 0.08),
            highlightColor:
                DashboardShellPalette.statusBlue.withValues(alpha: 0.04),
            hoverColor:
                DashboardShellPalette.statusBlue.withValues(alpha: 0.03),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      icon,
                      color: DashboardShellPalette.statusBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: type.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: type.caption.copyWith(
                              color: DashboardShellPalette.mutedInk,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    trailing ??
                        Icon(
                          onTap == null
                              ? Icons.hourglass_top_rounded
                              : Icons.chevron_right_rounded,
                          color: DashboardShellPalette.mutedInk,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardSettingsRecoveryRow extends StatelessWidget {
  const DashboardSettingsRecoveryRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.isBusy,
    required this.actionKey,
    required this.onUndo,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final bool isBusy;
  final Key actionKey;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final stackedAction = MediaQuery.sizeOf(context).width < 390 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.12;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: type.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: type.caption.copyWith(
                color: DashboardShellPalette.mutedInk,
                height: 1.28,
              ),
        ),
        if (statusLabel != subtitle) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            statusLabel,
            style: type.label.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ],
    );
    final action = TextButton(
      key: actionKey,
      onPressed: isBusy ? null : onUndo,
      child: Text(isBusy ? 'Working...' : 'Undo'),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: stackedAction
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                details,
                const SizedBox(height: 8),
                action,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: details),
                const SizedBox(width: 10),
                action,
              ],
            ),
    );
  }
}

class DashboardSettingsGroupDivider extends StatelessWidget {
  const DashboardSettingsGroupDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 28),
      height: 1,
      color: DashboardShellPalette.outline.withValues(alpha: 0.6),
    );
  }
}
