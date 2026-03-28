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
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: 'Close',
        padding: EdgeInsets.zero,
        splashRadius: 24,
        style: IconButton.styleFrom(
          backgroundColor: DashboardShellPalette.nestedPaper,
          foregroundColor: DashboardShellPalette.softInk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            side: const BorderSide(color: DashboardShellPalette.outline),
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
    return Align(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: DashboardShellPalette.outlineStrong,
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
    return DashboardPanel(
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: DashboardRadii.card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DashboardBadge(
            label: title,
            backgroundColor: DashboardShellPalette.nestedPaper,
            foregroundColor: DashboardShellPalette.softInk,
          ),
          const SizedBox(height: DashboardSpacing.small),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: DashboardSpacing.xSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: DashboardShellPalette.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: type.supporting.copyWith(
                            color: DashboardShellPalette.softInk,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: DashboardPanel(
          key: sheetKey,
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: DashboardRadii.sheet,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const DashboardSheetHandle(),
                const SizedBox(height: 10),
                const DashboardBadge(
                  label: 'Trust details',
                  icon: Icons.lock_outline_rounded,
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
                            title,
                            style: type.screenTitle.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: type.supporting.copyWith(
                              color: DashboardShellPalette.mutedInk,
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
