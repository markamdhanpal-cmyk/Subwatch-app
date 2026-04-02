import '../repositories/in_memory_ledger_repository.dart';
import '../repositories/in_memory_service_evidence_bucket_repository.dart';
import '../../domain/contracts/resolver.dart';
import '../../domain/contracts/service_evidence_bucket_repository.dart';
import '../../domain/entities/message_record.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/entities/subscription_event.dart';
import '../../domain/resolvers/deterministic_resolver.dart';
import '../../v2/decision/enums/decision_execution_mode.dart';
import '../../v2/decision/models/shadow_decision_comparison.dart';
import '../../v2/detection/models/canonical_input.dart';
import 'event_pipeline_use_case.dart';
import 'ingestion_use_case.dart';
import 'resolver_pipeline_use_case.dart';
import 'scan_subscriptions_v3_use_case.dart';

class LocalIngestionFlowUseCase {
  factory LocalIngestionFlowUseCase({
    InMemoryLedgerRepository? ledgerRepository,
    ServiceEvidenceBucketRepository? serviceEvidenceBucketRepository,
    EventPipelineUseCase? eventPipeline,
    Resolver? resolver,
    DecisionExecutionMode decisionExecutionMode =
        DecisionExecutionMode.bridgeToLedger,
    bool useEvidenceFirstV3 = true,
  }) {
    final repository = ledgerRepository ?? InMemoryLedgerRepository();
    final evidenceBucketRepository = serviceEvidenceBucketRepository ??
        InMemoryServiceEvidenceBucketRepository();
    final scanUseCase = useEvidenceFirstV3
        ? ScanSubscriptionsV3UseCase(
            ledgerRepository: repository,
            serviceEvidenceBucketRepository: evidenceBucketRepository,
          )
        : null;
    return LocalIngestionFlowUseCase._(
      ledgerRepository: repository,
      decisionExecutionMode: decisionExecutionMode,
      scanSubscriptionsV3UseCase: scanUseCase,
      ingestionUseCase: IngestionUseCase(
        eventPipeline: eventPipeline ?? EventPipelineUseCase(),
        resolverPipeline: ResolverPipelineUseCase(
          resolver: resolver ?? const DeterministicResolver(),
          ledgerRepository: repository,
        ),
        ledgerRepository: repository,
        serviceEvidenceBucketRepository: evidenceBucketRepository,
        decisionExecutionMode: decisionExecutionMode,
      ),
    );
  }

  const LocalIngestionFlowUseCase._({
    required InMemoryLedgerRepository ledgerRepository,
    required DecisionExecutionMode decisionExecutionMode,
    required ScanSubscriptionsV3UseCase? scanSubscriptionsV3UseCase,
    required IngestionUseCase ingestionUseCase,
  })  : _ledgerRepository = ledgerRepository,
        _decisionExecutionMode = decisionExecutionMode,
        _scanSubscriptionsV3UseCase = scanSubscriptionsV3UseCase,
        _ingestionUseCase = ingestionUseCase;

  final InMemoryLedgerRepository _ledgerRepository;
  final DecisionExecutionMode _decisionExecutionMode;
  final ScanSubscriptionsV3UseCase? _scanSubscriptionsV3UseCase;
  final IngestionUseCase _ingestionUseCase;

  ShadowDecisionComparison? get lastShadowComparison =>
      _scanSubscriptionsV3UseCase == null
          ? _ingestionUseCase.lastShadowComparison
          : null;

  Future<({List<SubscriptionEvent> events, List<ServiceLedgerEntry> ledgerEntries})>
      execute(List<MessageRecord> messages) async {
    final scanUseCase = _scanSubscriptionsV3UseCase;
    final events = scanUseCase == null
        ? await _ingestionUseCase.execute(messages)
        : (await scanUseCase.executeMessages(
            messages,
            mode: _decisionExecutionMode,
          ))
            .events;
    final ledgerEntries = await _ledgerRepository.list();
    return (events: events, ledgerEntries: ledgerEntries);
  }

  Future<({List<SubscriptionEvent> events, List<ServiceLedgerEntry> ledgerEntries})>
      executeCanonicalInputs(List<CanonicalInput> inputs) async {
    final scanUseCase = _scanSubscriptionsV3UseCase;
    final events = scanUseCase == null
        ? await _ingestionUseCase.executeCanonicalInputs(inputs)
        : (await scanUseCase.executeCanonicalInputs(
            inputs,
            mode: _decisionExecutionMode,
          ))
            .events;
    final ledgerEntries = await _ledgerRepository.list();
    return (events: events, ledgerEntries: ledgerEntries);
  }
}
