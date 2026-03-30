import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/connectors/noop_bank_evidence_connector.dart';
import 'package:sub_killer/application/contracts/bank_evidence_connector.dart';
import 'package:sub_killer/application/mappers/normalized_bank_transaction_canonical_input_mapper.dart';
import 'package:sub_killer/application/models/bank_connector_models.dart';
import 'package:sub_killer/application/repositories/in_memory_service_evidence_bucket_repository.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/service_evidence_source_kind.dart';
import 'package:sub_killer/v2/detection/bridges/bank_evidence_connector_canonical_input_source_adapter.dart';
import 'package:sub_killer/v2/detection/models/canonical_input.dart';

void main() {
  group('Bank connector abstraction stub', () {
    test('noop bank connector returns a safe empty pull result', () async {
      const connector = NoopBankEvidenceConnector();

      final result = await connector.pullTransactions();

      expect(result.connectorId, 'bank_connector_stub');
      expect(result.connectionReady, isFalse);
      expect(result.records, isEmpty);
      expect(result.note, contains('stub'));
    });

    test('bank mapper emits canonical bank transaction inputs with provenance', () {
      const mapper = NormalizedBankTransactionCanonicalInputMapper();
      final record = NormalizedBankTransactionRecord(
        id: 'bank-1',
        connectorId: 'bank_stub',
        observedAt: DateTime(2026, 3, 26, 10, 30),
        description: 'NETFLIX monthly subscription debit',
        direction: BankTransactionDirection.debit,
        channel: BankTransactionChannel.card,
        accountProviderLabel: 'HDFC Bank',
        accountReference: 'XX1212',
        amount: 499,
        merchantHint: 'NETFLIX',
        serviceHint: 'Netflix',
        reference: 'TXN123',
        rawSummary: 'Card debit received from connector.',
        batchId: 'bank-batch-1',
        postingState: BankTransactionPostingState.posted,
        captureConfidence: CanonicalInputCaptureConfidence.high,
      );

      final canonicalInput = mapper.map(record);

      expect(canonicalInput.kind, CanonicalInputKind.bankTransaction);
      expect(
        canonicalInput.origin.kind,
        CanonicalInputOriginKind.bankConnectorSync,
      );
      expect(canonicalInput.origin.sourceLabel, 'bank_stub');
      expect(canonicalInput.origin.batchId, 'bank-batch-1');
      expect(canonicalInput.senderHandle, 'HDFC Bank');
      expect(
        canonicalInput.textBody,
        contains('Bank connector debit transaction'),
      );
    });

    test('bank connector adapter reuses shared canonical ingestion path',
        () async {
      final adapter = BankEvidenceConnectorCanonicalInputSourceAdapter(
        connector: _FakeBankEvidenceConnector(
          connectorId: 'bank_stub',
          records: <NormalizedBankTransactionRecord>[
            NormalizedBankTransactionRecord(
              id: 'bank-2',
              connectorId: 'bank_stub',
              observedAt: DateTime(2026, 3, 26, 10, 30),
              description: 'Netflix subscription renewed successfully',
              direction: BankTransactionDirection.debit,
              channel: BankTransactionChannel.card,
              accountProviderLabel: 'HDFC Bank',
              amount: 499,
              merchantHint: 'NETFLIX',
              serviceHint: 'Netflix',
              postingState: BankTransactionPostingState.posted,
            ),
          ],
        ),
      );
      final bucketRepository = InMemoryServiceEvidenceBucketRepository();
      final useCase = LocalIngestionFlowUseCase(
        serviceEvidenceBucketRepository: bucketRepository,
      );

      final result = await useCase.executeCanonicalInputs(
        await adapter.loadCanonicalInputs(),
      );
      final buckets = await bucketRepository.list();

      expect(result.events, hasLength(1));
      expect(result.events.single.serviceKey.value, 'NETFLIX');
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);
      expect(
        buckets.single.sourceKindsSeen,
        contains(ServiceEvidenceSourceKind.bankConnectorSync),
      );
    });
  });
}

class _FakeBankEvidenceConnector implements BankEvidenceConnector {
  const _FakeBankEvidenceConnector({
    required this.connectorId,
    required this.records,
  });

  @override
  final String connectorId;

  final List<NormalizedBankTransactionRecord> records;

  @override
  Future<BankConnectorPullResult> pullTransactions({
    DateTime? since,
    String? cursor,
  }) async {
    return BankConnectorPullResult(
      connectorId: connectorId,
      records: records,
      connectionReady: true,
      syncCursor: cursor,
      note: 'Fake connector for tests.',
    );
  }
}
