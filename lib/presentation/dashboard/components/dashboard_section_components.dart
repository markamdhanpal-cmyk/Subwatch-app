import 'package:flutter/material.dart';

import '../dashboard_primitives.dart';

class DashboardInsetListGroup extends StatelessWidget {
  const DashboardInsetListGroup({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      tone: DashboardPanelTone.inset,
      elevation: DashboardPanelElevation.flat,
      radius: DashboardRadii.nested,
      padding: EdgeInsets.zero,
      child: Column(
        children: children
            .expand(
              (child) => <Widget>[
                child,
                if (child != children.last)
                  const Divider(
                    height: 1,
                    indent: DashboardListRowRhythm.dividerInset,
                    endIndent: DashboardListRowRhythm.dividerInset,
                    color: DashboardShellPalette.divider,
                  ),
              ],
            )
            .toList(growable: false),
      ),
    );
  }
}

class DashboardSectionBlock extends StatelessWidget {
  const DashboardSectionBlock({
    super.key,
    required this.title,
    required this.children,
    this.countLabel,
    this.caption,
  });

  final String title;
  final List<Widget> children;
  final String? countLabel;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return DashboardSectionFrame(
      title: title,

      countLabel: countLabel,
      caption: caption,
      children: children,
    );
  }
}

class DashboardEmptySection extends StatelessWidget {
  const DashboardEmptySection({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.eyebrow,
    this.tone = DashboardEmptyStateTone.neutral,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? eyebrow;
  final DashboardEmptyStateTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DashboardEmptyState(
      title: title,
      message: message,
      icon: icon,
      eyebrow: eyebrow,
      tone: tone,
      action: action,
    );
  }
}
