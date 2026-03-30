import '../models/bank_connector_models.dart';

abstract interface class BankEvidenceConnector {
  String get connectorId;

  Future<BankConnectorPullResult> pullTransactions({
    DateTime? since,
    String? cursor,
  });
}
