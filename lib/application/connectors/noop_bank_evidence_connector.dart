import '../contracts/bank_evidence_connector.dart';
import '../models/bank_connector_models.dart';

class NoopBankEvidenceConnector implements BankEvidenceConnector {
  const NoopBankEvidenceConnector({
    this.connectorId = 'bank_connector_stub',
    this.note = 'Bank connector stub: no live integration configured.',
  });

  @override
  final String connectorId;

  final String note;

  @override
  Future<BankConnectorPullResult> pullTransactions({
    DateTime? since,
    String? cursor,
  }) async {
    return BankConnectorPullResult(
      connectorId: connectorId,
      records: const <NormalizedBankTransactionRecord>[],
      connectionReady: false,
      syncCursor: cursor,
      note: note,
    );
  }
}
