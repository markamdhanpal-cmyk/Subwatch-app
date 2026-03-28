import 'package:flutter/material.dart';

import '../dashboard_primitives.dart';
import 'dashboard_section_components.dart';

enum DashboardSettingsRowTone {
  neutral,
  destructive,
}

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
    return DashboardPanel(
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: DashboardRadii.card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              style: type.sectionTitle.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: type.supporting.copyWith(
                color: DashboardShellPalette.mutedInk,
                height: 1.28,
              ),
            ),
          ],
          const SizedBox(height: DashboardSpacing.small),
          Container(
            decoration: BoxDecoration(
              color: DashboardShellPalette.elevatedPaper.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(DashboardRadii.nested),
              border: Border.all(
                color: DashboardShellPalette.outline.withValues(alpha: 0.82),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSettingsSubsection extends StatelessWidget {
  const DashboardSettingsSubsection({
    super.key,
    required this.title,
    this.caption,
    required this.children,
  });

  final String title;
  final String? caption;
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
            style: type.sectionTitle.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (caption != null && caption!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            caption!,
            style: type.supporting.copyWith(
              color: DashboardShellPalette.mutedInk,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 9),
        ] else
          const SizedBox(height: 8),
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
    this.subtitle,
    this.onTap,
    this.trailing,
    this.tone = DashboardSettingsRowTone.neutral,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final DashboardSettingsRowTone tone;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final stackTrailing =
        trailing != null &&
        (MediaQuery.sizeOf(context).width < 380 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.12);
    final iconColor = tone == DashboardSettingsRowTone.destructive
        ? DashboardShellPalette.caution
        : DashboardShellPalette.softInk;
    final iconBackground = tone == DashboardSettingsRowTone.destructive
        ? DashboardShellPalette.cautionSoft
        : DashboardShellPalette.nestedPaper;
    final interactiveTint = tone == DashboardSettingsRowTone.destructive
        ? DashboardShellPalette.caution
        : DashboardShellPalette.accent;
    final semanticsLabel = <String>[
      title,
      if (hasSubtitle) subtitle!,
    ].join('. ');
    final trailingWidget = trailing == null
        ? Icon(
            onTap == null
                ? Icons.hourglass_top_rounded
                : Icons.chevron_right_rounded,
            color: DashboardShellPalette.mutedInk,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              trailing!,
              if (onTap != null) ...<Widget>[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DashboardShellPalette.mutedInk,
                ),
              ],
            ],
          );

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel.isEmpty ? null : '$semanticsLabel.',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: tileKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: interactiveTint.withValues(alpha: 0.08),
            highlightColor: interactiveTint.withValues(alpha: 0.04),
            hoverColor: interactiveTint.withValues(alpha: 0.03),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: hasSubtitle
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: tone == DashboardSettingsRowTone.destructive
                                  ? DashboardShellPalette.caution.withValues(
                                      alpha: 0.28,
                                    )
                                  : DashboardShellPalette.outline,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 18,
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
                              if (hasSubtitle) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: type.supporting.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                    height: 1.28,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!stackTrailing) ...<Widget>[
                          const SizedBox(width: 8),
                          trailingWidget,
                        ] else if (onTap != null) ...<Widget>[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: DashboardShellPalette.mutedInk,
                          ),
                        ],
                      ],
                    ),
                    if (stackTrailing) ...<Widget>[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 50),
                        child: trailing!,
                      ),
                    ],
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
        if (statusLabel != subtitle) ...<Widget>[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: DashboardShellPalette.nestedPaper,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: DashboardShellPalette.outline,
              ),
            ),
            child: Text(
              statusLabel,
              style: type.meta.copyWith(
                color: DashboardShellPalette.softInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
    final action = TextButton.icon(
      key: actionKey,
      onPressed: isBusy ? null : onUndo,
      icon: const Icon(Icons.undo_rounded, size: 18),
      label: Text(isBusy ? 'Working...' : 'Undo'),
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
      margin: const EdgeInsets.only(left: 48),
      height: 1,
      color: DashboardShellPalette.divider,
    );
  }
}

class DashboardSettingsTrustPanel extends StatelessWidget {
  const DashboardSettingsTrustPanel({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final label = <String>[
      title,
      if (subtitle != null && subtitle!.isNotEmpty) subtitle!,
    ].join('. ');

    return Semantics(
      container: true,
      label: label.isEmpty ? null : '$label.',
      child: ExcludeSemantics(
        child: DashboardPanel(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF221915),
              DashboardShellPalette.paper,
            ],
          ),
          borderColor: DashboardShellPalette.outlineStrong,
          radius: DashboardRadii.prominentCard,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      DashboardShellPalette.nestedPaper,
                      DashboardShellPalette.registerPaper,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DashboardRadii.button),
                  border: Border.all(
                    color: DashboardShellPalette.outline,
                  ),
                ),
                child: Stack(
                  children: const <Widget>[
                    Center(
                      child: Icon(
                        Icons.smartphone_rounded,
                        size: 19,
                        color: DashboardShellPalette.ink,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Icon(
                        Icons.shield_rounded,
                        size: 16,
                        color: DashboardShellPalette.statusBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const DashboardBadge(
                      label: 'Trust center',
                      icon: Icons.lock_outline_rounded,
                      backgroundColor: DashboardShellPalette.nestedPaper,
                      foregroundColor: DashboardShellPalette.softInk,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: type.rowTitle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: type.supporting.copyWith(
                          color: DashboardShellPalette.softInk,
                          height: 1.28,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Recovery, reminders, and local controls stay transparent here.',
                      style: type.meta.copyWith(
                        color: DashboardShellPalette.mutedInk,
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
