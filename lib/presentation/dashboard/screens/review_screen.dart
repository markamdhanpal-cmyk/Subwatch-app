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
  final reviewRows = shell._buildReviewRows(
    data.reviewQueue,
    emptyTitle: 'Nothing to review right now',
    emptyMessage: '',
  );
  final reviewCount = data.reviewQueue.length;

  return ListView(
    key: const ValueKey<String>('destination-review-surface'),
    padding: DashboardSpacing.secondaryScreenInset,
    children: reviewCount == 0
        ? <Widget>[
            const _ReviewDecisionDeskHeader(reviewCount: 0),
            const SizedBox(height: DashboardSpacing.screenBlockGap),
            const _ReviewDeskEmptyState(),
          ]
        : <Widget>[
            _ReviewDecisionDeskHeader(reviewCount: reviewCount),
            const SizedBox(height: DashboardSpacing.screenBlockGap),
            _DashboardSection(
              key: const ValueKey<String>('section-reviewQueue'),
              title: 'Needs your review',
              countLabel: reviewCount == 1 ? '1 item' : '$reviewCount items',
              caption:
                  'Kept separate so your confirmed list stays careful until you decide.',
              children: reviewRows,
            ),
          ],
  );
}
