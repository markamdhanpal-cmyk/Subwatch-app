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
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: DashboardShellPalette.mutedInk.withValues(alpha: 0.45),
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
      backgroundColor: DashboardShellPalette.elevatedPaper,
      borderColor: DashboardShellPalette.outline,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: type.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                      item,
                      style: type.caption.copyWith(
                            color: DashboardShellPalette.ink,
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
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: sheetKey,
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const DashboardSheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: type.heading,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: type.caption.copyWith(
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
