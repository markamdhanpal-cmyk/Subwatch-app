import '../../domain/contracts/dashboard_projection.dart';
import '../../domain/contracts/ledger_repository.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';

class ProjectDashboardUseCase {
  const ProjectDashboardUseCase({
    required LedgerRepository ledgerRepository,
    required DashboardProjection dashboardProjection,
  })  : _ledgerRepository = ledgerRepository,
        _dashboardProjection = dashboardProjection;

  final LedgerRepository _ledgerRepository;
  final DashboardProjection _dashboardProjection;

  Future<({List<DashboardCard> cards, List<ReviewItem> reviewQueue})> execute() async {
    final entries = await _ledgerRepository.list();
    return (
      cards: _dashboardProjection.buildCards(entries),
      reviewQueue: _dashboardProjection.buildReviewQueue(entries),
    );
  }
}
