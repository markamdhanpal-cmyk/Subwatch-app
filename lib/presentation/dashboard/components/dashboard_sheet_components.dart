import 'package:flutter/material.dart';

import '../dashboard_primitives.dart';

class DashboardSheetCloseButton extends StatelessWidget {
  const DashboardSheetCloseButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.dashboardColors;
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: 'Close',
        padding: EdgeInsets.zero,
        splashRadius: 24,
        style: IconButton.styleFrom(
          backgroundColor: colors.nestedPaper,
          foregroundColor: colors.softInk,
          overlayColor: colors.accent.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            side: BorderSide(color: colors.outlineStrong),
          ),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class DashboardSheetHandle extends StatelessWidget {
  const DashboardSheetHandle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.dashboardColors;
    return Align(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: colors.outlineStrong,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class DashboardTrustSection extends StatelessWidget {
  const DashboardTrustSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    return DashboardPanel(
      tone: DashboardPanelTone.trust,
      elevation: DashboardPanelElevation.flat,
      radius: DashboardRadii.card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DashboardBadge(
            label: title,
            tone: DashboardBadgeTone.neutral,
          ),
          const SizedBox(height: DashboardSpacing.small),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: DashboardSpacing.xSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: type.supporting.copyWith(
                            color: colors.softInk,
                            height: 1.28,
                          ),
                    ),
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

class DashboardDetailSheet extends StatelessWidget {
  const DashboardDetailSheet({
    super.key,
    required this.sheetKey,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final Key sheetKey;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: DashboardPanel(
          key: sheetKey,
          tone: DashboardPanelTone.elevated,
          elevation: DashboardPanelElevation.prominent,
          radius: DashboardRadii.sheet,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const DashboardSheetHandle(),
                const SizedBox(height: 10),
                DashboardBadge(
                  label: 'Trust details',
                  icon: Icons.lock_outline_rounded,
                  backgroundColor: colors.nestedPaper,
                  foregroundColor: colors.softInk,
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
                            title,
                            style: type.screenTitle.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: type.supporting.copyWith(
                              color: colors.mutedInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DashboardSheetCloseButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
