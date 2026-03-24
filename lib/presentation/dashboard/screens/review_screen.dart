part of '../dashboard_shell.dart';

class _DashboardReviewScreen extends ConsumerWidget {
  const _DashboardReviewScreen({
    required this.shell,
  });

  final _DashboardShellState shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenData = ref.watch(dashboardReviewScreenDataProvider);
    ref.watch(
      dashboardReviewActionsProvider.select(
        (state) => state.targetsInFlight,
      ),
    );
    return _buildDashboardReviewScreen(
      shell: shell,
      data: screenData.data,
    );
  }
}

Widget _buildDashboardReviewScreen({
  required _DashboardShellState shell,
  required RuntimeDashboardSnapshot data,
}) {
  final isEmpty = data.reviewQueue.isEmpty;

  return ListView(
    key: const ValueKey<String>('destination-review-surface'),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),

    children: <Widget>[
      _ReviewQueueSummaryCard(
        reviewCount: data.reviewQueue.length,
      ),
      const SizedBox(height: 12),
      if (!isEmpty)
        _DashboardSection(
          key: const ValueKey<String>('section-reviewQueue'),
          title: 'Items for your review',
          countLabel: shell._reviewItemCountLabel(data.reviewQueue.length),
          caption: 'Decide these now. Undo later if needed.',
          children: shell._buildReviewRows(
            data.reviewQueue,
            emptyTitle: 'Nothing to review right now',
            emptyMessage: 'New uncertain items show up here.',
          ),
        ),

    ],
  );
}
