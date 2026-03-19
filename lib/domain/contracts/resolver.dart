import '../entities/service_ledger_entry.dart';
import '../entities/subscription_event.dart';

abstract interface class Resolver {
  ServiceLedgerEntry resolve({
    required SubscriptionEvent event,
    ServiceLedgerEntry? currentEntry,
  });
}
