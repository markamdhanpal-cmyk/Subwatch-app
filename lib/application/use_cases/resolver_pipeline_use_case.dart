import '../../domain/contracts/ledger_repository.dart';
import '../../domain/contracts/resolver.dart';
import '../../domain/entities/subscription_event.dart';

class ResolverPipelineUseCase {
  const ResolverPipelineUseCase({
    required Resolver resolver,
    required LedgerRepository ledgerRepository,
  })  : _resolver = resolver,
        _ledgerRepository = ledgerRepository;

  final Resolver _resolver;
  final LedgerRepository _ledgerRepository;

  Future<void> execute(List<SubscriptionEvent> events) async {
    for (final event in events) {
      final currentEntry = await _ledgerRepository.read(event.serviceKey);
      final nextEntry = _resolver.resolve(
        event: event,
        currentEntry: currentEntry,
      );
      await _ledgerRepository.write(nextEntry);
    }
  }
}
