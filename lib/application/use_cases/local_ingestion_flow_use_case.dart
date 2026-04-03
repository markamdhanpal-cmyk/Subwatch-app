import '../repositories/in_memory_ledger_repository.dart';
import '../repositories/in_memory_service_evidence_bucket_repository.dart';
import '../../domain/contracts/service_evidence_bucket_repository.dart';
import '../../domain/entities/message_record.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/entities/subscription_event.dart';
import '../../v2/decision/enums/decision_execution_mode.dart';
import '../../v2/decision/models/shadow_decision_comparison.dart';
import '../../v2/detection/models/canonical_input.dart';
import 'ingestion_use_case.dart';
import 'scan_subscriptions_v3_use_case.dart';

class LocalIngestionFlowUseCase {
  factory LocalIngestionFlowUseCase({
    InMemoryLedgerRepository? ledgerRepository,
    ServiceEvidenceBucketRepository? serviceEvidenceBucketRepository,
    DecisionExecutionMode decisionExecutionMode =
        DecisionExecutionMode.bridgeToLedger,
  }) {
    final repository = ledgerRepository ?? InMemoryLedgerRepository();
    final evidenceBucketRepository = serviceEvidenceBucketRepository ??
        InMemoryServiceEvidenceBucketRepository();
    final scanUseCase = ScanSubscriptionsV3UseCase(
      ledgerRepository: repository,
      serviceEvidenceBucketRepository: evidenceBucketRepository,
    );
    return LocalIngestionFlowUseCase._(
      ledgerRepository: repository,
      ingestionUseCase: IngestionUseCase(
        scanSubscriptionsV3UseCase: scanUseCase,
        decisionExecutionMode: decisionExecutionMode,
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

  ShadowDecisionComparison? get lastShadowComparison =>
      _ingestionUseCase.lastShadowComparison;

  Future<
      ({
        List<SubscriptionEvent> events,
        List<ServiceLedgerEntry> ledgerEntries
      })> execute(List<MessageRecord> messages) async {
    final events = await _ingestionUseCase.execute(messages);
    final ledgerEntries = await _ledgerRepository.list();
    return (events: events, ledgerEntries: ledgerEntries);
  }

  Future<
      ({
        List<SubscriptionEvent> events,
        List<ServiceLedgerEntry> ledgerEntries
      })> executeCanonicalInputs(List<CanonicalInput> inputs) async {
    final events = await _ingestionUseCase.executeCanonicalInputs(inputs);
    final ledgerEntries = await _ledgerRepository.list();
    return (events: events, ledgerEntries: ledgerEntries);
  }
}
