import '../../domain/contracts/dashboard_projection.dart';
import '../../domain/contracts/ledger_repository.dart';
import '../../domain/entities/review_item.dart';

class ProjectReviewQueueUseCase {
  const ProjectReviewQueueUseCase({
    required LedgerRepository ledgerRepository,
    required DashboardProjection dashboardProjection,
  })  : _ledgerRepository = ledgerRepository,
        _dashboardProjection = dashboardProjection;

  final LedgerRepository _ledgerRepository;
  final DashboardProjection _dashboardProjection;

  Future<List<ReviewItem>> execute() async {
    final entries = await _ledgerRepository.list();
    return _dashboardProjection.buildReviewQueue(entries);
  }
}
