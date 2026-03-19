import '../entities/dashboard_card.dart';
import '../entities/review_item.dart';
import '../entities/service_ledger_entry.dart';

abstract interface class DashboardProjection {
  List<DashboardCard> buildCards(Iterable<ServiceLedgerEntry> entries);

  List<ReviewItem> buildReviewQueue(Iterable<ServiceLedgerEntry> entries);
}
