import '../repositories/in_memory_ledger_repository.dart';
import '../../domain/contracts/resolver.dart';
import '../../domain/entities/message_record.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/entities/subscription_event.dart';
import '../../domain/resolvers/deterministic_resolver.dart';
import 'event_pipeline_use_case.dart';
import 'ingestion_use_case.dart';
import 'resolver_pipeline_use_case.dart';

class LocalIngestionFlowUseCase {
  factory LocalIngestionFlowUseCase({
    InMemoryLedgerRepository? ledgerRepository,
    EventPipelineUseCase? eventPipeline,
    Resolver? resolver,
  }) {
    final repository = ledgerRepository ?? InMemoryLedgerRepository();
    return LocalIngestionFlowUseCase._(
      ledgerRepository: repository,
      ingestionUseCase: IngestionUseCase(
        eventPipeline: eventPipeline ?? EventPipelineUseCase(),
        resolverPipeline: ResolverPipelineUseCase(
          resolver: resolver ?? const DeterministicResolver(),
          ledgerRepository: repository,
        ),
      ),
    );
  }

  const LocalIngestionFlowUseCase._({
    required InMemoryLedgerRepository ledgerRepository,
    required IngestionUseCase ingestionUseCase,
  })  : _ledgerRepository = ledgerRepository,
        _ingestionUseCase = ingestionUseCase;

  final InMemoryLedgerRepository _ledgerRepository;
  final IngestionUseCase _ingestionUseCase;

  Future<({List<SubscriptionEvent> events, List<ServiceLedgerEntry> ledgerEntries})>
  execute(List<MessageRecord> messages) async {
    final events = await _ingestionUseCase.execute(messages);
    final ledgerEntries = await _ledgerRepository.list();
    return (events: events, ledgerEntries: ledgerEntries);
  }
}
